# Guía paso a paso: implementación del caso BookApp

Esta guía describe cómo construir la aplicación **BookApp** siguiendo una arquitectura limpia, modular y basada en **BLoC**, usando como referencia la estructura del proyecto Easy Vet. No incluye código fuente explícito, solo la estructura de carpetas, nombres de clases, responsabilidades y el orden recomendado de implementación.

---

## 1. Alcance y requisitos principales

La aplicación debe permitir:

- **Login** con correo institucional y contraseña.
- **Home** con tres pestañas:
  1. **Books:** catálogo general de libros desde la API.
  2. **Favorites:** libros marcados como favoritos, persistidos **localmente**.
  3. **Reading List:** libros agregados a la lista de lectura, gestionada **en línea**.
- **Detalle de libro** con ficha técnica completa y acciones para favoritos y lista de lectura.
- **Persistencia local** de favoritos usando SQLite (`sqflite`) u equivalente.
- **Gestión de estado obligatoria** con **BLoC** (`flutter_bloc`).
- **Nombres e identificadores en inglés**.
- **Interfaz moderna** basada en Material Design 3.
- **Manejo claro de errores** (login fallido, sin conexión, etc.).

---

## 2. Stack tecnológico recomendado

```yaml
dependencies:
  flutter:
    sdk: flutter
  http:                # Consumo de API REST
  flutter_bloc:        # Gestión de estado obligatoria
  get_it:              # Inyección de dependencias
  provider:            # Opcional, para dependencias globales si se requiere
  flutter_secure_storage:  # Almacenamiento seguro del token
  sqflite:             # Base de datos local para favoritos
  path:                # Rutas de archivos locales
  cached_network_image: # Caché de imágenes de portadas
```

> **Nota:** Dado que BLoC es obligatorio, se recomienda unificar el manejo de estado con `Cubit` o `Bloc` en todas las features (auth, books, favorites, reading list).

---

## 3. Arquitectura y organización

Se propone una **Clean Architecture simplificada** organizada por features:

```
lib/
├── core/                 # Recursos compartidos
│   ├── api/              # Configuración central de la API
│   ├── database/         # Base de datos local
│   ├── di/               # Inyección de dependencias
│   ├── error/            # Excepciones y manejo de errores
│   ├── storage/          # Almacenamiento seguro
│   └── usecases/         # Casos de uso reutilizables (opcional)
│
├── features/
│   ├── auth/             # Login
│   ├── books/            # Catálogo y detalle de libros
│   ├── favorites/        # Favoritos (persistencia local)
│   ├── reading_list/     # Lista de lectura (persistencia remota)
│   └── main/             # Navegación principal con tabs
│
└── main.dart
```

Cada feature sigue la misma división interna:

```
features/<feature>/
├── data/
│   ├── local/            # DAOs, entidades locales
│   ├── remote/           # DTOs, servicios REST
│   └── repositories/     # Implementaciones de repositorios
├── domain/
│   ├── models/           # Entidades de dominio
│   └── repositories/     # Interfaces de repositorios
└── presentation/
    ├── bloc/             # Estados, eventos y BLoCs
    ├── pages/            # Pantallas
    └── widgets/          # Widgets propios de la feature
```

---

## 4. Estructura de carpetas completa propuesta

```
lib/
├── core/
│   ├── api/
│   │   └── api_config.dart
│   ├── database/
│   │   └── app_database.dart
│   ├── di/
│   │   └── dependency_injection.dart
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── storage/
│   │   └── token_storage.dart
│   └── utils/
│       └── extensions.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_service.dart
│   │   │   ├── auth_repository_impl.dart
│   │   │   ├── login_request_dto.dart
│   │   │   └── login_response_dto.dart
│   │   ├── domain/
│   │   │   ├── user.dart
│   │   │   └── auth_repository.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── login_bloc.dart
│   │       │   ├── login_event.dart
│   │       │   └── login_state.dart
│   │       ├── pages/
│   │       │   └── login_page.dart
│   │       └── widgets/
│   │           └── login_form.dart
│   │
│   ├── books/
│   │   ├── data/
│   │   │   ├── remote/
│   │   │   │   ├── book_dto.dart
│   │   │   │   └── book_service.dart
│   │   │   └── repositories/
│   │   │       └── book_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── book.dart
│   │   │   └── book_repository.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── books_bloc.dart
│   │       │   ├── books_event.dart
│   │       │   ├── books_state.dart
│   │       │   ├── book_detail_bloc.dart
│   │       │   ├── book_detail_event.dart
│   │       │   └── book_detail_state.dart
│   │       ├── pages/
│   │       │   ├── books_page.dart
│   │       │   └── book_detail_page.dart
│   │       └── widgets/
│   │           ├── book_list_item.dart
│   │           └── book_detail_actions.dart
│   │
│   ├── favorites/
│   │   ├── data/
│   │   │   ├── local/
│   │   │   │   ├── favorite_book_dao.dart
│   │   │   │   └── favorite_book_entity.dart
│   │   │   └── repositories/
│   │   │       └── favorites_repository_impl.dart
│   │   ├── domain/
│   │   │   └── favorites_repository.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── favorites_bloc.dart
│   │       │   ├── favorites_event.dart
│   │       │   └── favorites_state.dart
│   │       ├── pages/
│   │       │   └── favorites_page.dart
│   │       └── widgets/
│   │           └── favorite_list_item.dart
│   │
│   ├── reading_list/
│   │   ├── data/
│   │   │   ├── remote/
│   │   │   │   ├── reading_list_item_dto.dart
│   │   │   │   └── reading_list_service.dart
│   │   │   └── repositories/
│   │   │       └── reading_list_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── reading_list_item.dart
│   │   │   └── reading_list_repository.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── reading_list_bloc.dart
│   │       │   ├── reading_list_event.dart
│   │       │   └── reading_list_state.dart
│   │       ├── pages/
│   │       │   └── reading_list_page.dart
│   │       └── widgets/
│   │           └── reading_list_item_card.dart
│   │
│   └── main/
│       └── presentation/
│           ├── pages/
│           │   └── main_page.dart
│           └── widgets/
│               └── bottom_navigation.dart
│
└── main.dart
```

---

## 5. Paso 0: Configuración inicial

1. Crear el proyecto con Flutter:
   - `flutter create book_app`
2. Agregar las dependencias indicadas en el `pubspec.yaml`.
3. Ejecutar `flutter pub get`.
4. Configurar permisos de Internet en Android (`AndroidManifest.xml`) y iOS (`Info.plist`).
5. Explorar la API con Swagger/Postman:
   - Identificar endpoints de login, libros, lista de lectura.
   - Verificar estructura de JSON de respuesta.
   - Confirmar encabezados de autenticación (Bearer token).

---

## 6. Paso 1: Construir la capa `core`

### 6.1 Configuración de API
- Clase `ApiConfig` para centralizar la URL base y rutas principales.

### 6.2 Base de datos local
- Clase `AppDatabase` para inicializar `sqflite`.
- Definir el esquema de la tabla de favoritos.

### 6.3 Almacenamiento seguro
- Clase `TokenStorage` para guardar, leer y eliminar el token JWT usando `flutter_secure_storage`.

### 6.4 Inyección de dependencias
- Archivo `dependency_injection.dart` con `GetIt`.
- Registrar:
  - `ApiConfig`
  - `AppDatabase`
  - `FlutterSecureStorage`
  - `TokenStorage`
  - Servicios, repositorios y BLoCs de cada feature.

### 6.5 Manejo de errores
- Clases `ServerException`, `CacheException`, `NetworkException`.
- Clases `ServerFailure`, `CacheFailure`, `NetworkFailure` para presentación.

---

## 7. Paso 2: Feature de autenticación (`auth`)

### Dominio
- `User`: modelo con first name, last name, email, token.
- `AuthRepository`: interfaz con método `login`.

### Datos
- `LoginRequestDto`: campos `email` y `password`.
- `LoginResponseDto`: parseo del JSON de login y conversión a `User`.
- `AuthService`: petición POST al endpoint de login.
- `AuthRepositoryImpl`: llama al servicio, guarda el token en `TokenStorage` y retorna el `User`.

### Presentación
- `LoginEvent`: eventos `LoginSubmitted`.
- `LoginState`: estados `LoginInitial`, `LoginLoading`, `LoginSuccess`, `LoginFailure`.
- `LoginBloc`: recibe el evento, emite estados, maneja errores con mensajes claros.
- `LoginPage`: formulario con campos de correo y contraseña.
- `LoginForm`: widget con los `TextField` y el botón de login.

> **Recomendación:** validar campos vacíos antes de enviar y mostrar un `CircularProgressIndicator` durante `LoginLoading`.

---

## 8. Paso 3: Feature de catálogo de libros (`books`)

### Dominio
- `Book`: entidad con `id`, `title`, `author`, `publisher`, `year`, `genre`, `description`, `rating`, `coverUrl`.
- `BookRepository`: interfaz con método `getBooks()`.

### Datos
- `BookDto`: modelo de parseo JSON del endpoint de libros.
- `BookService`: petición GET al endpoint de libros.
- `BookRepositoryImpl`: transforma DTOs a entidades de dominio.

### Presentación

#### Catálogo
- `BooksEvent`: eventos `BooksLoaded`, `BooksRefreshed`.
- `BooksState`: estados `BooksInitial`, `BooksLoading`, `BooksLoaded`, `BooksFailure`.
- `BooksBloc`: obtiene libros y emite estados.
- `BooksPage`: muestra lista o grid de libros.
- `BookListItem`: card con portada, título, autor, género y calificación.

#### Detalle de libro
- `BookDetailEvent`:
  - `BookDetailLoaded(bookId)`: carga el libro y consulta si es favorito y si está en la reading list.
  - `FavoriteToggled(bookId)`: agrega o quita el libro de favoritos.
  - `ReadingListToggled(bookId)`: agrega o quita el libro de la lista de lectura.
- `BookDetailState`: estado con `book`, `isFavorite`, `isInReadingList`, `isLoading`, `errorMessage`.
- `BookDetailBloc`:
  - Carga el detalle del libro.
  - Consulta el estado de favorito (local) y de reading list (desde la lista remota o un estado previo).
  - Ejecuta los toggles y refresca el estado de los botones.
- `BookDetailPage`: ficha técnica completa y acciones.
- `BookDetailActions`: widget con botones para agregar/quitar favoritos y lista de lectura.

---

## 9. Paso 4: Feature de favoritos (`favorites`)

### Dominio
- Reutilizar la entidad `Book` del catálogo para mantener consistencia en la UI.
- `FavoritesRepository`: interfaz con métodos `getFavorites()`, `addFavorite(book)`, `removeFavorite(id)`, `isFavorite(id)`.

> **Nota:** no se agrega `isFavorite` a `Book`. El modelo `Book` sigue siendo puro y representa únicamente el catálogo. El estado de favorito se maneja en el BLoC y en la base de datos local.

### Datos
- `FavoriteBookEntity`: representación de la tabla SQLite.
- `FavoriteBookDao`: acceso a la tabla (insert, delete, query, exists).
- `FavoritesRepositoryImpl`: implementa la lógica de persistencia local.

### Presentación
- `FavoritesEvent`: eventos `FavoritesLoaded`, `FavoriteAdded`, `FavoriteRemoved`.
- `FavoritesState`: estados `FavoritesInitial`, `FavoritesLoading`, `FavoritesLoaded`, `FavoritesFailure`.
- `FavoritesBloc`: carga, agrega y elimina favoritos.
- `FavoritesPage`: lista de favoritos.
- `FavoriteListItem`: card con información y opción de eliminar.

> **Consejo:** al entrar al detalle de un libro, consultar si ya es favorito para mostrar el estado correcto del botón.
>
> **Reutilización de widgets:** como `Book` e `ReadingListItem` comparten campos visuales (portada, título, autor, género, calificación), crea un widget genérico `BookCard` que acepte esos campos y, opcionalmente, un `addedAt`. Úsalo en `BooksPage`, `FavoritesPage` y `ReadingListPage` para evitar duplicar código.

---

## 10. Paso 5: Feature de lista de lectura (`reading_list`)

### Dominio
- `ReadingListItem`: entidad con `bookId`, `title`, `author`, `publisher`, `year`, `genre`, `overview`, `rating`, `coverUrl`, `addedAt`.
  - Incluye todos los campos del libro más la fecha `addedAt` devuelta por la API.
- `ReadingListRepository`: interfaz con métodos:
  - `Future<List<ReadingListItem>> getReadingList()`
  - `Future<void> toggleReadingListItem(int bookId)`

> **Importante:** la API usa un único endpoint `POST /api/readlists` para alternar (toggle). Si el `bookId` no está en la lista, se agrega; si ya está, se elimina.

### Datos
- `ReadingListItemDto`: parseo del JSON del endpoint `GET /api/readlists`.
  - Campos esperados: `bookId`, `title`, `author`, `publisher`, `year`, `genre`, `overview`, `rating`, `cover`, `addedAt`.
- `ReadingListService`:
  - `getReadingList()`: petición `GET` autenticada con Bearer token.
  - `toggleReadingListItem(int bookId)`: petición `POST` con body `{ "bookId": bookId }`.
- `ReadingListRepositoryImpl`: transforma DTOs a entidades de dominio.

### Presentación
- `ReadingListEvent`:
  - `ReadingListLoaded`: carga la lista actual.
  - `ReadingListToggled(int bookId)`: alterna la presencia de un libro en la lista.
- `ReadingListState`: estados `ReadingListInitial`, `ReadingListLoading`, `ReadingListLoaded`, `ReadingListFailure`.
- `ReadingListBloc`:
  - Carga la lista desde el servidor.
  - Ejecuta el toggle y vuelve a cargar la lista para reflejar el nuevo estado.
- `ReadingListPage`: lista de libros agregados.
- `ReadingListItemCard`: card con portada, título, autor, género, calificación y fecha de agregado.

---

## 11. Paso 6: Pantalla principal con navegación inferior (`main`)

- `MainPage`: `StatefulWidget` con `BottomNavigationBar` de tres tabs.
- Tabs:
  - Índice 0: `BooksPage`
  - Índice 1: `FavoritesPage`
  - Índice 2: `ReadingListPage`
- `BottomNavigation`: widget opcional para separar la barra de navegación.

> **Nota:** usar `BottomNavigationBarType.fixed` para mostrar siempre las tres etiquetas.

---

## 12. Paso 7: Punto de entrada `main.dart`

1. Llamar a `setupDependencies()` antes de `runApp`.
2. Proveer los BLoCs globales con `MultiBlocProvider`:
   - `LoginBloc`
   - `BooksBloc`
   - `FavoritesBloc`
   - `ReadingListBloc`
3. Configurar `MaterialApp` con:
   - `debugShowCheckedModeBanner: false`
   - `home: LoginPage`
   - Tema basado en Material Design 3.

---

## 13. Paso 8: Diseño de UI/UX (Material Design 3)

- Usar `ThemeData` con `useMaterial3: true`.
- Aplicar `Cards`, `Chips`, `FloatingActionButton`, `Icons` de Material.
- Mostrar imágenes de portadas con `CachedNetworkImage`.
- Usar `Hero` para transición entre lista y detalle.
- Implementar `RefreshIndicator` en listas para recargar datos.
- Mantener nombres de clases, métodos y variables en **inglés**.

---

## 14. Paso 9: Manejo de errores

- Capturar excepciones en repositorios y transformarlas a `Failure`.
- En BLoCs, emitir estados de error con mensajes amigables:
  - "Invalid credentials"
  - "No internet connection"
  - "Failed to load books"
  - "Could not update reading list"
- Mostrar `SnackBar` o mensajes en pantalla según el estado.

---

## 15. Paso 10: Pruebas y preparación de entrega

1. Probar todos los endpoints antes con Postman/Swagger.
2. Validar flujo completo:
   - Login → Home → Books → Detalle → Favoritos → Reading List.
   - Cierre y reapertura de la app para verificar persistencia local.
3. Revisar que no haya errores de compilación.
4. Ejecutar `flutter clean` antes de comprimir el proyecto.
5. Empaquetar el proyecto en `.zip`.

---

## 16. Checklist final

- [ ] Proyecto creado y dependencias instaladas.
- [ ] Capa `core` configurada (API, base de datos, storage, DI, errores).
- [ ] Feature `auth` implementada con BLoC.
- [ ] Feature `books` con catálogo y detalle.
- [ ] Feature `favorites` con persistencia local SQLite.
- [ ] Feature `reading_list` con persistencia remota API.
- [ ] `MainPage` con tres tabs funcional.
- [ ] `main.dart` configurado con `MultiBlocProvider`.
- [ ] UI basada en Material Design 3.
- [ ] Manejo de errores claro y amigable.
- [ ] Nombres de clases e identificadores en inglés.
- [ ] `flutter clean` ejecutado antes de comprimir.

---

## 17. Consideraciones importantes

- **BLoC es obligatorio:** evita mezclar con `ChangeNotifier`; usa `BlocBuilder`/`BlocListener`/`BlocConsumer` en toda la UI.
- **Separación de responsabilidades:** no llames a `http` directamente desde la UI; siempre pasa por service → repository → BLoC.
- **Seguridad:** nunca guardes el token en `SharedPreferences` sin cifrado; usa `flutter_secure_storage`.
- **Offline:** la lista de favoritos debe funcionar sin internet; la reading list depende de conexión.
- **Modularidad:** cada feature debe poder desarrollarse y probarse de forma independiente.

---

Con esta guía puedes desarrollar **BookApp** de forma ordenada, cumpliendo todos los requisitos funcionales, arquitectónicos y de calidad solicitados en el caso.
