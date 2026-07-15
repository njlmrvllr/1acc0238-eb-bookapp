import 'package:bookapp/features/home/data/book_repository_impl.dart';
import 'package:bookapp/features/home/data/bool_service.dart';
import 'package:bookapp/features/home/domain/book_repository.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<BookService>(() => BookService());
  getIt.registerLazySingleton<BookRepository>(
    () => BookRepositoryImpl(service: getIt<BookService>()),
  );
}