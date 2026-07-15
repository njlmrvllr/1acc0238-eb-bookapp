import 'package:bookapp/features/home/domain/book_repository.dart';
import 'package:bookapp/features/home/presentation/home_state.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  HomeState state = const HomeState();
  final BookRepository bookRepository;

  HomeViewModel({required this.bookRepository});

  Future<void> getBooks() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final books = await bookRepository.getBooks();
      state = state.copyWith(books: books, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }

    notifyListeners();
  }
}