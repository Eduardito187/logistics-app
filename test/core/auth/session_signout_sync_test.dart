import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/clients/auth_client.dart';
import 'package:logistics_app/core/api/models/message_response.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/background/sync_scheduler.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/failure_reporter.dart';
import 'package:logistics_app/core/offline/photo_upload_queue.dart';

import '../offline/offline_test_fakes.dart';
import 'test_fakes.dart';

// Política de la cola offline al cerrar sesión: se intenta subir lo pendiente
// con el token vigente (antes de revocarlo), lo que no sube se conserva para la
// próxima sesión y se limpian las fallidas ya reportadas.

/// API con `execution` guionizado y `auth` falso (para `appLogout`).
class _Api extends FakeSyncApi {
  _Api(super.execution, this._auth);
  final FakeAuthClient _auth;
  @override
  AuthClient get auth => _auth;
}

void main() {
  late AppDatabase db;
  late Directory tmp;
  late ScriptedExecution exec;
  late FakeAuthClient authClient;
  late ProviderContainer container;

  /// Llamadas al API de ejecución registradas cuando se revocó el token.
  int? execCallsAtLogout;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('signout_test_');
    exec = ScriptedExecution();
    authClient = _OrderedAuthClient(() => execCallsAtLogout = exec.calls);
    execCallsAtLogout = null;
    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(FakeSecureStorage()),
        appDatabaseProvider.overrideWithValue(db),
        logisticsApiProvider.overrideWithValue(_Api(exec, authClient)),
        failureReporterProvider.overrideWithValue(RecordingReporter()),
        syncSchedulerProvider.overrideWithValue(CountingScheduler()),
        pendingPhotosDirectoryProvider.overrideWithValue(() async => tmp),
      ],
    );
    // La app abre la base al arrancar (drainOnStartup); acá se simula.
    container.read(appDatabaseProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<void> action(String id, String status) => db.enqueue(
    OutboxActionsCompanion.insert(
      id: id,
      kind: 'recordLoadScan',
      payload:
          '{"shipment_id":"s1","unit_id":"u1","lat":0,"lng":0,'
          '"occurred_at":"2026-10-15T12:00:00.000Z"}',
      occurredAt: DateTime.utc(2026, 10, 15),
      status: Value(status),
    ),
  );

  Future<List<OutboxAction>> rows() => db.select(db.outboxActions).get();

  Future<void> login() => container
      .read(sessionProvider.notifier)
      .signIn(token: 'tok', userName: 'ana', role: UserRole.driver);

  test('sube lo pendiente ANTES de revocar el token', () async {
    await login();
    await action('A', 'pending');
    await container.read(sessionProvider.notifier).signOut();
    expect(await rows(), isEmpty);
    expect(execCallsAtLogout, 1);
    expect(container.read(sessionProvider), isNull);
  });

  test('sin red: conserva la cola pendiente y borra las fallidas', () async {
    await login();
    await action('P', 'pending');
    await action('F', 'failed');
    exec.enqueue([connectionError()]);
    await container.read(sessionProvider.notifier).signOut();
    final remaining = await rows();
    expect(remaining.single.id, 'P');
    expect(remaining.single.status, 'pending');
    expect(container.read(sessionProvider), isNull);
  });

  test('sin pendientes: no llama al API de ejecución', () async {
    await login();
    await container.read(sessionProvider.notifier).signOut();
    expect(exec.calls, 0);
    expect(authClient.logoutCalls, 1);
  });

  test('dev-login (sin token): no drena, pero limpia fallidas', () async {
    container.read(sessionProvider.notifier).devSignIn(UserRole.driver);
    await action('P', 'pending');
    await action('F', 'failed');
    await container.read(sessionProvider.notifier).signOut();
    expect(exec.calls, 0);
    expect((await rows()).single.id, 'P');
  });
}

/// Auth falso que avisa en el momento de la revocación.
class _OrderedAuthClient extends FakeAuthClient {
  _OrderedAuthClient(this._onLogout);
  final void Function() _onLogout;

  @override
  Future<MessageResponse> appLogout() {
    _onLogout();
    return super.appLogout();
  }
}
