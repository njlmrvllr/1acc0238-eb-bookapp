import 'package:bookapp/features/home/presentation/home_state.dart';
import 'package:bookapp/features/home/presentation/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().getBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final HomeViewModel viewModel = context.watch<HomeViewModel>();
    final HomeState state = viewModel.state;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(state.errorMessage!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('BookApp')),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: state.books.length,
        itemBuilder: (context, index) {
          final book = state.books[index];
          return Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(book.title),
                Text(book.author),
              ],
            ),
          );
        },
      ),
    );
  }
}