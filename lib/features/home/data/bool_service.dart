import 'dart:convert';
import 'dart:io';

import 'package:bookapp/features/home/data/book_dto.dart';
import 'package:http/http.dart' as http;

class BookService {
  final url = "https://bookapp-gveteaa0dqf0eycn.eastus-01.azurewebsites.net/api/books";

    Future<List<BookDto>> getBooks() async {
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == HttpStatus.ok) {
      final json = jsonDecode(response.body);
      final List jsons = json["results"];
      return jsons.map((json) => BookDto.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }
}