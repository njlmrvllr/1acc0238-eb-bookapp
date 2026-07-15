class BookDto { 
  final int id;
  final String title;
  final String author;
  final String cover;
  final String publisher;
  final int year;
  final double rating;
  final String genre;
  final String overview;

  const BookDto ({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.publisher,
    required this.year,
    required this.rating,
    required this.genre,
    required this.overview,
  });

  factory BookDto.fromJson(Map<String, dynamic> json) {
    return BookDto(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      cover: json['cover'],
      publisher: json['publisher'],
      year: json['year'],
      rating: json['rating'],
      genre: json['genre'],
      overview: json['overview'],
    );
  }
}