import 'package:bookapp/core/di/dependency_injection.dart';
import 'package:bookapp/features/home/domain/book_repository.dart';
import 'package:bookapp/features/home/presentation/home_page.dart';
import 'package:bookapp/features/home/presentation/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(bookRepository: getIt<BookRepository>()),
      child: MaterialApp(
        title: 'BookApp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
