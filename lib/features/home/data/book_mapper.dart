
import 'package:bookapp/features/home/data/book_dto.dart';
import 'package:bookapp/features/home/domain/book.dart';

extension BookMapper on BookDto {
  Book toDomain() {
    return Book(
      id: id,
      title: title,
      author: author,
      cover: cover,
      publisher: publisher,
      year: year,
      rating: rating,
      genre: genre,
      overview: overview,
    );
  }
}