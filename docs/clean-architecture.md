# Arquitectura del cliente — DDD + CQRS + Clean Architecture (SRP)

Convención **única y obligatoria** para todos los features de `lib/features/<f>/`. La app es un cliente
que **solo consume el backend** (`/api/v1/app/*`), pero se estructura con las mismas ideas que el backend:
dominio aislado, inversión de dependencias, una responsabilidad por clase (SRP) y separación lectura/escritura
(CQRS).

## Regla de dependencias (Clean)

```
presentation  →  domain  ←  data
(controllers)   (use cases,   (data source + repository impl)
 + screens      repo interface)
```

- `presentation` depende de **casos de uso** (nunca de `data` ni del cliente API).
- `data` depende de `domain` (implementa sus interfaces).
- `domain` **no depende de nada de Flutter ni de `lib/core/api`** salvo los **modelos del contrato
  OpenAPI**, que se tratan como el dato del dominio del cliente (son datos inmutables puros; no se
  duplican con mappers salvo que el cliente agregue comportamiento/invariantes propios — ej. `labels`,
  `dashboard_metrics`, `preparation_state`, que sí viven como **entidades** en `domain/entities/`).

## Capas por feature

```
lib/features/<f>/
├── data/
│   ├── datasources/<f>_remote_data_source.dart   # ÚNICO lugar que toca logisticsApiProvider / api.*
│   └── repositories/<f>_repository_impl.dart     # implementa la interfaz de domain
├── domain/
│   ├── entities/            # solo si hay comportamiento/invariantes propios del cliente
│   ├── repositories/<f>_repository.dart          # interfaz (contrato) abstracta
│   └── usecases/            # UN caso de uso por operación (SRP), CQRS: Query (lee) / Command (escribe)
└── presentation/
    ├── controllers/         # Notifier/AsyncNotifier o FutureProvider; dependen de casos de uso
    ├── widgets/
    └── *_screen.dart, <f>_routes.dart
```

## Reglas concretas

1. **Data source** (`data/datasources/`): única clase que importa `logisticsApiProvider`/`api.<module>`.
   Cada método espeja un endpoint, devuelve el modelo generado (DTO) desde `.data`, y convierte el error:
   `on DioException catch(e){ throw ApiException.fromDio(e); }`. Provider: `<f>RemoteDataSourceProvider`.
2. **Interfaz de repositorio** (`domain/repositories/`): `abstract interface class <F>Repository` con los
   métodos del feature (tipados con los modelos del contrato o entidades propias).
3. **Impl de repositorio** (`data/repositories/`): `class <F>RepositoryImpl implements <F>Repository`,
   delega en el data source. Provider `<f>RepositoryProvider` que devuelve el **tipo interfaz**.
4. **Casos de uso** (`domain/usecases/`): **una clase por operación** (SRP). Nombrá **Query** las lecturas
   y **Command** las escrituras (CQRS). Firma uniforme:
   ```dart
   class GetFooList {                    // Query (lectura)
     const GetFooList(this._repo);
     final FooRepository _repo;
     Future<List<Foo>> call() => _repo.listFoo();
   }
   class ApproveFoo {                    // Command (escritura)
     const ApproveFoo(this._repo);
     final FooRepository _repo;
     Future<void> call(String id) => _repo.approve(id);
   }
   ```
   Un provider por caso de uso: `final getFooListProvider = Provider((ref) => GetFooList(ref.watch(fooRepositoryProvider)));`
5. **Presentation**: los controllers (Riverpod) y las pantallas **solo** usan casos de uso vía sus
   providers. **Prohibido** `ref.read(logisticsApiProvider)` fuera de `data/datasources/`. Las lecturas
   siguen usando `AsyncValueView`; las escrituras muestran loading + SnackBar + invalidan.
6. **Errores**: `ApiException` (lib/core/network) es el *Failure* del dominio del cliente. El data source
   la lanza; los casos de uso la propagan; el controller la captura en `AsyncValue`/try-catch.
7. **Offline**: las escrituras de terreno siguen pasando por `offlineQueueProvider.submit(...)`. En Clean,
   el caso de uso (Command) es quien llama a `submit`; el data source expone el método directo para el
   dispatcher. No se rompe el patrón offline-first.
8. **Contrato de integración intacto**: `<f>Tasks` y `<f>Routes` en `presentation/<f>_routes.dart`
   conservan sus nombres (el coordinador los cablea). No cambiar rutas ni `RoleTask`.
9. **SRP en pantallas**: una pantalla no mezcla acceso a datos con layout; delega en controllers/casos de uso.

## Definición de terminado (por feature)

`dart format lib/features/<f> test/features/<f>` + `flutter analyze lib/features/<f>` sin issues, y si
existe `test/features/<f>/` que `flutter test test/features/<f>` quede verde (actualizando esos tests si
cambiaron nombres internos). Mantener el comportamiento de las pantallas.
