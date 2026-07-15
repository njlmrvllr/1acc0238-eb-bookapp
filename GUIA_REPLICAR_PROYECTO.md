# Guía paso a paso: replicar un proyecto Flutter como Easy Vet

Este documento resume la arquitectura, organización y flujo de trabajo usados en la carpeta `lib` de **Easy Vet**, para que puedas crear un proyecto similar de forma ordenada.

---

## 1. ¿Qué vamos a construir?

Una aplicación Flutter de comercio electrónico (o similar) que:

- Consume una API REST pública o propia.
- Tiene **login** con JWT y persistencia segura del token.
- Muestra un **listado de productos** con imágenes y detalle.
- Permite agregar/ver/quitar productos de un **carrito**.
- Guarda datos localmente con **SQLite** como caché/offline.
- Usa **inyección de dependencias** y separa responsabilidades en capas.

---

## 2. Arquitectura y stack de dependencias

### Arquitectura: Clean Architecture simplificada

```
lib/
├── core/               # Recursos compartidos (DB, DI, storage)
└── features/
    └── <feature>/
        ├── data/       # Fuentes de datos (remoto/local) + implementación del repositorio
        ├── domain/     # Modelos de negocio + contratos (interfaces) de repositorios
        └── presentation/  # UI + estados + view models
```

### Dependencias principales (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.6.0
  provider: ^6.1.5+1
  get_it: ^8.0.2
  flutter_bloc: ^9.1.1
  flutter_secure_storage: ^10.3.1
  sqflite: ^2.4.3
  path: ^1.9.1
  cached_network_image: ^3.4.1
```

- `http`: llamadas REST.
- `provider` + `flutter_bloc`: manejo de estado.
- `get_it`: inyección de dependencias.
- `flutter_secure_storage`: almacenar token JWT.
- `sqflite` + `path`: base de datos local.
- `cached_network_image`: imágenes de red con caché.

---

## 3. Paso 0: Crear el proyecto base

```bash
flutter create mi_app
```

Luego reemplaza `pubspec.yaml` con las dependencias indicadas arriba y ejecuta:

```bash
flutter pub get
```

---

## 4. Paso 1: Configurar la capa `core`

Esta capa contiene todo lo que se comparte entre features.

### 4.1 Base de datos local (`lib/core/database/app_database.dart`)

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'mi_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            name TEXT,
            description TEXT,
            price REAL,
            image TEXT
          )
        ''');
      },
    );
  }
}
```

### 4.2 Almacenamiento seguro del token (`lib/core/storage/token_storage.dart`)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final String tokenKey = 'auth_token';
  final FlutterSecureStorage storage;

  const TokenStorage({required this.storage});

  Future<void> saveToken(String token) async {
    await storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: tokenKey);
  }

  Future<void> deleteToken() async {
    await storage.delete(key: tokenKey);
  }
}
```

### 4.3 Inyección de dependencias (`lib/core/di/dependency_injection.dart`)

Usa `get_it` para registrar servicios, DAOs, repositorios y view models.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<FlutterSecureStorage>(() => FlutterSecureStorage());
  getIt.registerLazySingleton<TokenStorage>(
    () => TokenStorage(storage: getIt<FlutterSecureStorage>()),
  );

  // Aquí irán los registros de cada feature
}
```

---

## 5. Paso 2: Crear una feature de autenticación (con BLoC/Cubit)

Este feature usa `flutter_bloc` con un `Cubit` para el login.

### 5.1 Modelo de dominio

`lib/features/auth/domain/user.dart`

```dart
class User {
  final String lastName;
  final String firstName;
  final String email;

  const User({
    required this.lastName,
    required this.firstName,
    required this.email,
  });
}
```

### 5.2 Contrato del repositorio

`lib/features/auth/domain/auth_repository.dart`

```dart
import 'package:mi_app/features/auth/domain/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
}
```

### 5.3 DTOs

`lib/features/auth/data/login_request_dto.dart`

```dart
class LoginRequestDto {
  final String email;
  final String password;

  const LoginRequestDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
```

`lib/features/auth/data/login_response_dto.dart`

```dart
import 'package:mi_app/features/auth/domain/user.dart';

class LoginResponseDto {
  final String token;
  final String lastName;
  final String firstName;
  final String email;

  const LoginResponseDto({
    required this.token,
    required this.lastName,
    required this.firstName,
    required this.email,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      token: json['token'],
      lastName: json['lastName'],
      firstName: json['firstName'],
      email: json['email'],
    );
  }

  User toDomain() {
    return User(lastName: lastName, firstName: firstName, email: email);
  }
}
```

### 5.4 Servicio remoto

`lib/features/auth/data/auth_service.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mi_app/features/auth/data/login_request_dto.dart';
import 'package:mi_app/features/auth/data/login_response_dto.dart';

class AuthService {
  final String baseUrl = 'https://tu-api.com/api/users/login';

  Future<LoginResponseDto> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
        LoginRequestDto(email: email, password: password).toJson(),
      ),
    );

    if (response.statusCode == HttpStatus.ok) {
      return LoginResponseDto.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to login');
  }
}
```

### 5.5 Implementación del repositorio

`lib/features/auth/data/auth_repository_impl.dart`

```dart
import 'package:mi_app/core/storage/token_storage.dart';
import 'package:mi_app/features/auth/data/auth_service.dart';
import 'package:mi_app/features/auth/domain/auth_repository.dart';
import 'package:mi_app/features/auth/domain/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService service;
  final TokenStorage tokenStorage;

  const AuthRepositoryImpl({required this.service, required this.tokenStorage});

  @override
  Future<User> login(String email, String password) async {
    final dto = await service.login(email, password);
    await tokenStorage.saveToken(dto.token);
    return dto.toDomain();
  }
}
```

### 5.6 Estado y ViewModel (Cubit)

`lib/features/auth/presentation/login_state.dart`

```dart
import 'package:mi_app/features/auth/domain/user.dart';

sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final User user;
  const LoginSuccess({required this.user});
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure({required this.message});
}
```

`lib/features/auth/presentation/login_view_model.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_app/features/auth/domain/auth_repository.dart';
import 'package:mi_app/features/auth/presentation/login_state.dart';

class LoginViewModel extends Cubit<LoginState> {
  final AuthRepository repository;

  LoginViewModel({required this.repository}) : super(const LoginInitial());

  Future<void> login(String email, String password) async {
    emit(const LoginLoading());
    try {
      final user = await repository.login(email, password);
      emit(LoginSuccess(user: user));
    } catch (e) {
      emit(LoginFailure(message: e.toString()));
    }
  }
}
```

### 5.7 UI

`lib/features/auth/presentation/login_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_app/features/auth/presentation/login_state.dart';
import 'package:mi_app/features/auth/presentation/login_view_model.dart';
import 'package:mi_app/features/main/presentation/main_page.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LoginViewModel, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainPage()),
            );
          }
          if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: email,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Email',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: password,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Password',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          context.read<LoginViewModel>().login(
                            email.text,
                            password.text,
                          );
                        },
                        child: const Text('Login'),
                      ),
                    ),
                  ),
                ],
              ),
              if (state is LoginLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}
```

### 5.8 Registrar en DI

```dart
getIt.registerLazySingleton<AuthService>(() => AuthService());
getIt.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(
    service: getIt<AuthService>(),
    tokenStorage: getIt<TokenStorage>(),
  ),
);
getIt.registerFactory<LoginViewModel>(
  () => LoginViewModel(repository: getIt<AuthRepository>()),
);
```

---

## 6. Paso 3: Crear una feature de listado de productos (con Provider)

Usa `ChangeNotifier` + `Provider`.

### 6.1 Modelo de dominio

`lib/features/home/domain/product.dart`

```dart
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String image;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
  });
}
```

### 6.2 Repositorio

`lib/features/home/domain/product_repository.dart`

```dart
import 'package:mi_app/features/home/domain/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
}
```

### 6.3 Datos remotos

`lib/features/home/data/remote/product_dto.dart`

```dart
class ProductDto {
  final int id;
  final String title;
  final double price;
  final String description;
  final String image;

  ProductDto({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.image,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'],
      title: json['title'],
      price: (json['price'] as num).toDouble(),
      description: json['description'],
      image: json['image'],
    );
  }
}
```

`lib/features/home/data/remote/product_service.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mi_app/features/home/data/remote/product_dto.dart';

class ProductService {
  final String _baseUrl = 'https://tu-api.com/api/products';

  Future<List<ProductDto>> getProducts() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == HttpStatus.ok) {
      final json = jsonDecode(response.body);
      final List maps = json['results'];
      return maps.map((map) => ProductDto.fromJson(map)).toList();
    }
    return [];
  }
}
```

### 6.4 Datos locales

`lib/features/home/data/local/product_entity.dart`

```dart
class ProductEntity {
  final int id;
  final String name;
  final String description;
  final double price;
  final String image;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'image': image,
  };

  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      image: map['image'],
    );
  }
}
```

`lib/features/home/data/local/product_dao.dart`

```dart
import 'package:mi_app/core/database/app_database.dart';
import 'package:mi_app/features/home/data/local/product_entity.dart';
import 'package:sqflite/sqflite.dart';

class ProductDao {
  final AppDatabase appDatabase;

  const ProductDao({required this.appDatabase});

  Future<void> insertProduct(ProductEntity product) async {
    final db = await appDatabase.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProductEntity>> getProducts() async {
    final db = await appDatabase.database;
    final List maps = await db.query('products');
    return maps.map((map) => ProductEntity.fromMap(map)).toList();
  }
}
```

### 6.5 Implementación del repositorio (remoto + caché offline)

`lib/features/home/data/repositories/product_repository_impl.dart`

```dart
import 'package:mi_app/features/home/data/local/product_dao.dart';
import 'package:mi_app/features/home/data/local/product_entity.dart';
import 'package:mi_app/features/home/data/remote/product_dto.dart';
import 'package:mi_app/features/home/data/remote/product_service.dart';
import 'package:mi_app/features/home/domain/product.dart';
import 'package:mi_app/features/home/domain/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductService service;
  final ProductDao dao;

  const ProductRepositoryImpl({required this.service, required this.dao});

  @override
  Future<List<Product>> getProducts() async {
    try {
      final dtos = await service.getProducts();

      for (final dto in dtos) {
        await dao.insertProduct(ProductEntity(
          id: dto.id,
          name: dto.title,
          description: dto.description,
          price: dto.price,
          image: dto.image,
        ));
      }

      return dtos.map((dto) => Product(
        id: dto.id,
        name: dto.title,
        description: dto.description,
        price: dto.price,
        image: dto.image,
      )).toList();
    } catch (e) {
      final entities = await dao.getProducts();
      return entities.map((entity) => Product(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        price: entity.price,
        image: entity.image,
      )).toList();
    }
  }
}
```

### 6.6 Estado y ViewModel

`lib/features/home/presentation/home_state.dart`

```dart
import 'package:mi_app/features/home/domain/product.dart';

class HomeState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;

  HomeState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  HomeState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
```

`lib/features/home/presentation/home_view_model.dart`

```dart
import 'package:flutter/material.dart';
import 'package:mi_app/features/home/domain/product_repository.dart';
import 'package:mi_app/features/home/presentation/home_state.dart';

class HomeViewModel extends ChangeNotifier {
  final ProductRepository repository;
  HomeState state = HomeState();

  HomeViewModel({required this.repository}) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final products = await repository.getProducts();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load products: $e',
        isLoading: false,
      );
    }
    notifyListeners();
  }
}
```

### 6.7 UI básica

`lib/features/home/presentation/home_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app/features/home/presentation/home_view_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.state.errorMessage != null) {
      return Center(child: Text(viewModel.state.errorMessage!));
    }

    return GridView.builder(
      itemCount: viewModel.state.products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemBuilder: (context, index) {
        final product = viewModel.state.products[index];
        return Card(child: Text(product.name));
      },
    );
  }
}
```

### 6.8 Registrar en DI

```dart
getIt.registerLazySingleton<ProductService>(() => ProductService());
getIt.registerLazySingleton<ProductDao>(
  () => ProductDao(appDatabase: getIt<AppDatabase>()),
);
getIt.registerFactory<ProductRepository>(
  () => ProductRepositoryImpl(
    service: getIt<ProductService>(),
    dao: getIt<ProductDao>(),
  ),
);
getIt.registerFactory<HomeViewModel>(
  () => HomeViewModel(repository: getIt<ProductRepository>()),
);
```

---

## 7. Paso 4: Crear una feature de carrito (con Provider)

El carrito necesita el token del usuario para hacer peticiones autenticadas.

### 7.1 Modelo y repositorio

`lib/features/cart/domain/cart_item.dart`

```dart
class CartItem {
  final int productId;
  final String name;
  final double price;
  final String image;
  final String category;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.quantity,
  });
}
```

`lib/features/cart/domain/cart_repository.dart`

```dart
import 'package:mi_app/features/cart/domain/cart_item.dart';

abstract class CartRepository {
  Future<void> addToCart(int productId, int quantity);
  Future<void> removeFromCart(int productId);
  Future<List<CartItem>> getCartItems();
}
```

### 7.2 Servicio remoto

`lib/features/cart/data/cart_service.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mi_app/core/storage/token_storage.dart';
import 'package:mi_app/features/cart/data/cart_item_dto.dart';

class CartService {
  final TokenStorage storage;
  final String _baseUrl = 'https://tu-api.com/api/cart';

  const CartService({required this.storage});

  Future<String?> _getToken() async {
    final token = await storage.getToken();
    if (token == null) throw Exception('Token not found');
    return token;
  }

  Future<List<CartItemDto>> getCartItems() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      final json = jsonDecode(response.body);
      final List items = json['results'];
      return items.map((item) => CartItemDto.fromJson(item)).toList();
    }
    throw Exception('Failed to load cart items');
  }

  Future<void> addToCart(int productId, int quantity) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'productId': productId, 'quantity': quantity}),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw Exception('Failed to add item to cart');
    }
  }
}
```

### 7.3 Implementación del repositorio

```dart
import 'package:mi_app/features/cart/data/cart_service.dart';
import 'package:mi_app/features/cart/domain/cart_item.dart';
import 'package:mi_app/features/cart/domain/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final CartService service;

  const CartRepositoryImpl({required this.service});

  @override
  Future<void> addToCart(int productId, int quantity) async {
    await service.addToCart(productId, quantity);
  }

  @override
  Future<List<CartItem>> getCartItems() async {
    final dtos = await service.getCartItems();
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<void> removeFromCart(int productId) async {
    await service.addToCart(productId, 0);
  }
}
```

### 7.4 Estado y ViewModel

`lib/features/cart/presentation/cart_state.dart`

```dart
import 'package:mi_app/features/cart/domain/cart_item.dart';

class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? errorMessage;

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
```

`lib/features/cart/presentation/cart_view_model.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:mi_app/features/cart/domain/cart_repository.dart';
import 'package:mi_app/features/cart/presentation/cart_state.dart';

class CartViewModel extends ChangeNotifier {
  final CartRepository repository;
  CartState state = const CartState();

  CartViewModel({required this.repository}) {
    loadCartItems();
  }

  Future<void> loadCartItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final items = await repository.getCartItems();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
    notifyListeners();
  }

  Future<void> addToCart(int productId, int quantity) async {
    try {
      await repository.addToCart(productId, quantity);
      await loadCartItems();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  Future<void> removeFromCart(int productId) async {
    try {
      await repository.removeFromCart(productId);
      await loadCartItems();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }
}
```

### 7.5 Registrar en DI

```dart
getIt.registerLazySingleton<CartService>(
  () => CartService(storage: getIt<TokenStorage>()),
);
getIt.registerLazySingleton<CartRepository>(
  () => CartRepositoryImpl(service: getIt<CartService>()),
);
getIt.registerFactory<CartViewModel>(
  () => CartViewModel(repository: getIt<CartRepository>()),
);
```

---

## 8. Paso 5: Crear la página principal con navegación inferior

`lib/features/main/presentation/main_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:mi_app/features/cart/presentation/cart_page.dart';
import 'package:mi_app/features/home/presentation/home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    HomePage(),  // placeholder para Favoritos
    CartPage(),
    HomePage(),  // placeholder para Perfil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (value) => setState(() => selectedIndex = value),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

---

## 9. Paso 6: Punto de entrada `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:mi_app/core/di/dependency_injection.dart';
import 'package:mi_app/features/auth/presentation/login_page.dart';
import 'package:mi_app/features/auth/presentation/login_view_model.dart';
import 'package:mi_app/features/cart/presentation/cart_view_model.dart';
import 'package:mi_app/features/home/presentation/home_view_model.dart';

void main() {
  setupDependencies();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<HomeViewModel>()),
        BlocProvider(create: (_) => getIt<LoginViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<CartViewModel>()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
```

---

## 10. Checklist final

- [ ] `flutter pub get` ejecutado sin errores.
- [ ] Todos los archivos tienen los imports correctos (reemplaza `mi_app` por el nombre real de tu paquete).
- [ ] En Android e iOS agregaste el permiso de Internet.
- [ ] La `baseUrl` apunta a tu backend.
- [ ] La tabla de SQLite coincide con los campos de tu entidad.
- [ ] Los view models están registrados en `dependency_injection.dart`.
- [ ] Los providers están en `main.dart`.
- [ ] Compilas con `flutter run` y no hay errores de análisis.

---

## 11. Consejos y posibles mejoras

1. **Centraliza la URL base**: crea una clase `AppConfig` o `ApiConfig` en `core/` para no repetir URLs.
2. **Manejo de errores**: crea excepciones personalizadas en `core/error/` en lugar de usar `throw Exception(...)`.
3. **Unifica el state management**: actualmente el proyecto mezcla `Cubit` (auth) y `ChangeNotifier` (home/cart). Para un proyecto nuevo, elige uno solo (se recomienda `flutter_bloc` o `Riverpod`).
4. **Tests**: agrega unit tests para repositorios, servicios y view models.
5. **RefreshIndicator**: envuelve `HomePage` con `RefreshIndicator` para recargar productos.
6. **Logout**: agrega un botón de logout que borre el token y regrese al `LoginPage`.
7. **Navegación tipada**: considera usar `go_router` si la app crece.
8. **Modelos inmutables**: usa `freezed` o `@immutable` para evitar mutaciones accidentales.

---

## 12. Resumen de la estructura final

```
lib/
├── core/
│   ├── database/
│   │   └── app_database.dart
│   ├── di/
│   │   └── dependency_injection.dart
│   └── storage/
│       └── token_storage.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository_impl.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── login_request_dto.dart
│   │   │   └── login_response_dto.dart
│   │   ├── domain/
│   │   │   ├── auth_repository.dart
│   │   │   └── user.dart
│   │   └── presentation/
│   │       ├── login_page.dart
│   │       ├── login_state.dart
│   │       └── login_view_model.dart
│   ├── cart/
│   │   ├── data/
│   │   │   ├── cart_item_dto.dart
│   │   │   ├── cart_repository_impl.dart
│   │   │   └── cart_service.dart
│   │   ├── domain/
│   │   │   ├── cart_item.dart
│   │   │   └── cart_repository.dart
│   │   └── presentation/
│   │       ├── cart_page.dart
│   │       ├── cart_state.dart
│   │       ├── cart_view_model.dart
│   │       └── item.dart
│   ├── home/
│   │   ├── data/
│   │   │   ├── local/
│   │   │   │   ├── product_dao.dart
│   │   │   │   └── product_entity.dart
│   │   │   ├── remote/
│   │   │   │   ├── product_dto.dart
│   │   │   │   └── product_service.dart
│   │   │   └── repositories/
│   │   │       └── product_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── product.dart
│   │   │   └── product_repository.dart
│   │   └── presentation/
│   │       ├── home_page.dart
│   │       ├── home_state.dart
│   │       ├── home_view_model.dart
│   │       ├── product_detail_page.dart
│   │       └── product_item.dart
│   └── main/
│       └── presentation/
│           └── main_page.dart
└── main.dart
```

Con esta guía puedes crear un proyecto Flutter con la misma estructura y comportamiento que **Easy Vet**, adaptando modelos, URLs y detalles de UI a tus necesidades.
