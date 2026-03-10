class Game {
  final String id;
  final String title;
  final String platform;
  final String status;
  final int rating;

  Game({required this.id, required this.title, required this.platform, required this.status, required this.rating});

  factory Game.fromFirestore(String id, Map<String, dynamic> data) {
    return Game(
      id: id,
      title: data['title'] ?? '',
      platform: data['platform'] ?? 'PC',
      status: data['status'] ?? 'Chystám se',
      rating: data['rating'] ?? 3,
    );
  }
}