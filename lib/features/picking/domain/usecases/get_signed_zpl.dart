import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/picking_repository_impl.dart';
import '../repositories/picking_repository.dart';

/// Caso de uso (Query, CQRS): ZPL firmado por el backend para todo el pedido.
class GetSignedZpl {
  const GetSignedZpl(this._repo);

  final PickingRepository _repo;

  Future<String> call(String orderNumber) => _repo.getSignedZpl(orderNumber);
}

final getSignedZplProvider = Provider<GetSignedZpl>(
  (ref) => GetSignedZpl(ref.watch(pickingRepositoryProvider)),
);
