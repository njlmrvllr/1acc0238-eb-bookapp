
import 'package:bookapp/features/home/data/book_dto.dart';
import 'package:bookapp/features/home/data/book_mapper.dart';
import 'package:bookapp/features/home/data/bool_service.dart';
import 'package:bookapp/features/home/domain/book.dart';
import 'package:bookapp/features/home/domain/book_repository.dart';

class BookRepositoryImpl implements BookRepository {
  final BookService service;
  const BookRepositoryImpl({required this.service});

  @override
  Future<List<Book>> getBooks() async {
    final List<BookDto> dtos = await service.getBooks();
    return dtos.map((dto) => dto.toDomain()).toList();
  }
}