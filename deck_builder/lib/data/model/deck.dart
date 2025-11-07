class Deck {
  final String id;
  final String userId; 
  final String deckname;
  final bool public;
  final List<Map<String, dynamic>> cards;

  Deck({
    required this.id,
    required this.userId,
    required this.deckname,
    required this.public,
    required this.cards,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      deckname: json['deckName'] ?? '',
      public: json['public'] ?? false,
      cards: (json['decklist'] as List?)
              ?.map((c) => Map<String, dynamic>.from(c))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deckName': deckname,
      'public': public,
      'decklist': cards,
    };
  }
}
