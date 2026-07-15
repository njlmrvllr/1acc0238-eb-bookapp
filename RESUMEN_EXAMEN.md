# Resumen rápido para el examen - BookApp Flutter

Guía condensada para resolver un caso tipo **BookApp** mañana. Usa la misma arquitectura de las guías anteriores: **Clean Architecture simplificada + BLoC + get_it**.

---

## 1. Arquitectura de 3 capas

Para cada feature creas siempre:

```
features/<feature>/
├── domain/       # Modelos + interfaces de repositorio
├── data/         # DTOs, servicios HTTP, DAOs, implementación del repositorio
└── presentation/ # Bloc, Event, State, Pages, Widgets
```

Flujo de datos:

```
UI → Bloc → Repository → Service/DAO → API o SQLite
```

---

## 2. Orden de implementación recomendado

1. `core`
   - `ApiConfig` (URL base)
   - `AppDatabase` (SQLite)
   - `TokenStorage` (flutter_secure_storage)
   - `dependency_injection.dart` (GetIt)
2. `auth` → login, guardar token
3. `books` → catálogo + detalle
4. `favorites` → SQLite local
5. `reading_list` → API remota
6. `main` → navegación inferior
7. `main.dart` → MultiBlocProvider

---

## 3. Patrón rápido por feature

### Dominio
```dart
class FeatureModel { ... }

abstract class FeatureRepository {
  Future<List<FeatureModel>> getItems();
}
```

### Datos
- DTO: parseo de JSON (`fromJson`).
- Service: llamada HTTP (`http.get` / `http.post`).
- DAO (solo local): acceso a SQLite.
- RepositoryImpl: implementa la interfaz del dominio.

### Presentación (BLoC)
```dart
// Event
abstract class FeatureEvent {}
class FeatureLoaded extends FeatureEvent {}

// State
abstract class FeatureState {}
class FeatureLoading extends FeatureState {}
class FeatureLoaded extends FeatureState { final List<...> items; }
class FeatureFailure extends FeatureState { final String message; }

// Bloc
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final FeatureRepository repository;
  FeatureBloc(this.repository) : super(FeatureInitial()) {
    on<FeatureLoaded>((event, emit) async {
      emit(FeatureLoading());
      try {
        final items = await repository.getItems();
        emit(FeatureLoaded(items));
      } catch (e) {
        emit(FeatureFailure(e.toString()));
      }
    });
  }
}
```

### UI
```dart
BlocBuilder<FeatureBloc, FeatureState>(
  builder: (context, state) {
    if (state is FeatureLoading) return CircularProgressIndicator();
    if (state is FeatureFailure) return Text(state.message);
    if (state is FeatureLoaded) return ListView(...);
    return Container();
  },
)
```

---

## 4. Consejos clave para el examen

- **Siempre revisa el JSON en Swagger/Postman primero.** Los nombres de campos pueden variar (`cover` vs `coverUrl`, `overview` vs `description`, etc.).
- **No agregues campos de estado a los modelos del dominio.** `isFavorite` o `isInReadingList` van en el `State` del Bloc, no en `Book`.
- **El login debe guardar el token** con `flutter_secure_storage`.
- **Las llamadas autenticadas** llevan header:
  ```dart
  'Authorization': 'Bearer $token'
  ```
- **Si el endpoint alterna (toggle)**, usa un solo método `toggleItem(id)` y recarga la lista después.
- **Usa `BlocConsumer`** cuando necesites escuchar cambios (ej. navegar al home tras login) y construir UI al mismo tiempo.
- **Mantén nombres en inglés**: clases, métodos, archivos y variables.
- **UI Material 3**: usa `Card`, `BottomNavigationBar`, `CachedNetworkImage`, `Hero`, `RefreshIndicator`.
- **Manejo de errores**: muestra mensajes amigables como "Invalid credentials" o "Failed to load data".

---

## 5. Estructura mínima de carpetas

```
lib/
├── core/
│   ├── api/api_config.dart
│   ├── database/app_database.dart
│   ├── di/dependency_injection.dart
│   └── storage/token_storage.dart
├── features/
│   ├── auth/
│   ├── books/
│   ├── favorites/
│   ├── reading_list/
│   └── main/
└── main.dart
```

---

## 6. Checklist antes de entregar

- [ ] App compila y ejecuta sin errores fatales.
- [ ] Login funciona y guarda el token.
- [ ] Lista de libros se muestra correctamente.
- [ ] Detalle de libro navega y muestra todos los datos.
- [ ] Favoritos se guardan localmente y persisten al cerrar la app.
- [ ] Reading list carga y actualiza desde la API.
- [ ] Bottom navigation tiene las 3 pestañas funcionando.
- [ ] BLoC usado en todas las features.
- [ ] Nombres de clases/métodos en inglés.
- [ ] UI con Material Design 3.
- [ ] Manejo de errores visible para el usuario.
- [ ] `flutter clean` ejecutado antes de comprimir en `.zip`.

---

## 7. Dependencias mínimas en `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  http:
  flutter_bloc:
  get_it:
  flutter_secure_storage:
  sqflite:
  path:
  cached_network_image:
```

---

## 8. Frase clave

> "Domain define qué se hace, Data define cómo se hace, y Presentation reacciona a los estados."

¡Éxitos en el examen! 🚀
