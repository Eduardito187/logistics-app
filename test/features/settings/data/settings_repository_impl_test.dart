import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/clients/auth_client.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/api/models/device_list_item.dart';
import 'package:logistics_app/core/api/models/get_app_devices_response.dart';
import 'package:logistics_app/core/api/models/message_response.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:logistics_app/features/settings/domain/usecases/get_me.dart';
import 'package:logistics_app/features/settings/domain/usecases/list_devices.dart';
import 'package:logistics_app/features/settings/domain/usecases/revoke_device.dart';

// Capa data de settings. Dos niveles:
//  1. Repositorio + casos de uso (GetMe/ListDevices/RevokeDevice): delegan en el
//     data source, que acá es falso.
//  2. SettingsRemoteDataSource: convierte DioException en ApiException y
//     desenvuelve `.data` en listDevices.

const _me = AppMeResponse(
  user: AppUserProfile(
    id: 1,
    name: 'Juan',
    email: 'j@x.com',
    roles: ['chofer'],
  ),
  device: null,
  abilities: ['execution:write'],
);

const _device = DeviceListItem(
  uuid: 'uuid-1',
  platform: 'android',
  name: 'Zebra TC',
  lastSeenAt: null,
  revoked: false,
);

/// Data source falso para probar repositorio + casos de uso.
class _FakeSettingsRemote implements SettingsRemoteDataSource {
  final List<String> revoked = [];

  @override
  Future<AppMeResponse> getMe() async => _me;

  @override
  Future<List<DeviceListItem>> listDevices() async => const [_device];

  @override
  Future<void> revokeDevice(String uuid) async => revoked.add(uuid);
}

/// Cliente de auth falso para probar el data source real (conversión de error).
class _FakeAuthClient implements AuthClient {
  _FakeAuthClient({this.throws = false});
  final bool throws;

  DioException get _error => DioException(
    requestOptions: RequestOptions(path: '/x'),
    response: Response(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: 403,
      data: const {'title': 'Sin permiso'},
    ),
  );

  @override
  Future<AppMeResponse> appMe() async {
    if (throws) throw _error;
    return _me;
  }

  @override
  Future<GetAppDevicesResponse> listDevices() async {
    if (throws) throw _error;
    return const GetAppDevicesResponse(data: [_device]);
  }

  @override
  Future<MessageResponse> revokeDevice({required String uuid}) async {
    if (throws) throw _error;
    return const MessageResponse(message: 'ok');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeApi extends LogisticsApi {
  _FakeApi(this._authClient) : super(Dio());
  final AuthClient _authClient;
  @override
  AuthClient get auth => _authClient;
}

void main() {
  group('Repositorio + casos de uso', () {
    ProviderContainer container(_FakeSettingsRemote remote) {
      final c = ProviderContainer(
        overrides: [settingsRemoteDataSourceProvider.overrideWithValue(remote)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('GetMe devuelve el perfil', () async {
      final c = container(_FakeSettingsRemote());
      final me = await c.read(getMeProvider).call();
      expect(me.user.name, 'Juan');
      expect(me.abilities, contains('execution:write'));
    });

    test('ListDevices devuelve la lista', () async {
      final c = container(_FakeSettingsRemote());
      final devices = await c.read(listDevicesProvider).call();
      expect(devices, hasLength(1));
      expect(devices.first.uuid, 'uuid-1');
    });

    test('RevokeDevice delega el uuid al data source', () async {
      final remote = _FakeSettingsRemote();
      final c = container(remote);
      await c.read(revokeDeviceProvider).call('uuid-1');
      expect(remote.revoked, ['uuid-1']);
    });
  });

  group('SettingsRemoteDataSource', () {
    SettingsRemoteDataSource dataSource(_FakeAuthClient client) {
      final c = ProviderContainer(
        overrides: [logisticsApiProvider.overrideWithValue(_FakeApi(client))],
      );
      addTearDown(c.dispose);
      return c.read(settingsRemoteDataSourceProvider);
    }

    test('getMe ok: devuelve el perfil del cliente', () async {
      final me = await dataSource(_FakeAuthClient()).getMe();
      expect(me.user.name, 'Juan');
    });

    test('listDevices ok: desenvuelve .data', () async {
      final devices = await dataSource(_FakeAuthClient()).listDevices();
      expect(devices.single.uuid, 'uuid-1');
    });

    test('getMe con DioException: lanza ApiException', () async {
      await expectLater(
        dataSource(_FakeAuthClient(throws: true)).getMe(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
    });

    test('listDevices con DioException: lanza ApiException', () async {
      await expectLater(
        dataSource(_FakeAuthClient(throws: true)).listDevices(),
        throwsA(isA<ApiException>()),
      );
    });

    test('revokeDevice con DioException: lanza ApiException', () async {
      await expectLater(
        dataSource(_FakeAuthClient(throws: true)).revokeDevice('uuid-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
