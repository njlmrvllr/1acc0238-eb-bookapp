import 'package:bookapp/features/home/domain/book.dart';

abstract class BookRepository {
  Future<List<Book>> getBooks();
}