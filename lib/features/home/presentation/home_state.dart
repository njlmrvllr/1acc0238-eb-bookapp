import 'package:bookapp/features/home/domain/book.dart';

class HomeState {
  final List<Book> books;
  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    this.books = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  HomeState copyWith({
    List<Book>? books,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

}
