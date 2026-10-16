// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/corridor_type.dart';
import '../models/define_leg_request.dart';
import '../models/department.dart';
import '../models/leg_collection.dart';
import '../models/leg_envelope.dart';
import '../models/node_collection.dart';
import '../models/node_envelope.dart';
import '../models/node_status.dart';
import '../models/node_type.dart';
import '../models/operational_corridor_collection.dart';
import '../models/post_integrations_network_nodes_response.dart';
import '../models/register_node_request.dart';

part 'network_client.g.dart';

@RestApi()
abstract class NetworkClient {
  factory NetworkClient(Dio dio, {String? baseUrl}) = _NetworkClient;

  /// List network corridor legs (internal app gate).
  ///
  /// Devuelve los tramos/corredores de la red para la app interna. Filtro opcional por corredor.
  ///
  /// [corridorType] - Filter by corridor type.
  @GET('/app/network/legs')
  Future<LegCollection> listNetworkLegs({
    @Query('corridor_type') CorridorType? corridorType,
  });

  /// Get a single corridor leg by id (internal app gate).
  ///
  /// [leg] - Leg UUID.
  @GET('/app/network/legs/{leg}')
  Future<LegEnvelope> getNetworkLeg({@Path('leg') required String leg});

  /// List operational corridors in a department (internal app gate).
  ///
  /// Devuelve los corredores operativos de un departamento: el insumo con el que planning/promise.
  /// saben qué puede salir (y entrar) por ese departamento. Combina los tramos entre nodos activos.
  /// y los corredores terminales (última milla desde un CD, recojo en tienda) que cada nodo ofrece.
  ///
  /// [department] - Department to resolve corridors for.
  @GET('/app/network/corridors')
  Future<OperationalCorridorCollection> listOperationalCorridors({
    @Query('department') required Department department,
  });

  /// List network nodes (internal app gate).
  ///
  /// Devuelve los nodos de la red para la app interna. Filtros opcionales por tipo y estado.
  ///
  /// [type] - Filter by node type.
  ///
  /// [status] - Filter by operational status.
  @GET('/app/network/nodes')
  Future<NodeCollection> listNetworkNodes({
    @Query('type') NodeType? type,
    @Query('status') NodeStatus? status,
  });

  /// Get a single network node by id (internal app gate).
  ///
  /// [node] - Node UUID.
  @GET('/app/network/nodes/{node}')
  Future<NodeEnvelope> getNetworkNode({@Path('node') required String node});

  /// Define a corridor leg between two nodes (integrations gate)
  @POST('/integrations/network/legs')
  Future<LegEnvelope> defineNetworkLeg({
    @Body() required DefineLegRequest body,
  });

  /// Remove a corridor leg (integrations gate).
  ///
  /// [leg] - Leg UUID.
  @DELETE('/integrations/network/legs/{leg}')
  Future<void> removeNetworkLeg({@Path('leg') required String leg});

  /// Register a network node (integrations gate, SAP master data)
  @POST('/integrations/network/nodes')
  Future<PostIntegrationsNetworkNodesResponse> registerNetworkNode({
    @Body() required RegisterNodeRequest body,
  });

  /// Deactivate a network node (integrations gate, SAP master data).
  ///
  /// [node] - Node UUID.
  @DELETE('/integrations/network/nodes/{node}')
  Future<void> deactivateNetworkNode({@Path('node') required String node});
}
