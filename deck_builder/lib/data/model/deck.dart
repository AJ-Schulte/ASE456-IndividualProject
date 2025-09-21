import 'card.dart';
class Deck {
  late List<Card> cards;
  late String username;
  late String deckname;
  late bool public;

  Deck( 
    {
      required this.cards,
      required this.deckname,
      required this.public,
      required this.username
    }
  );

  Deck.fromJson(Map<String, dynamic> parsedJson) {
    cards = (parsedJson['decklist'] as List<dynamic>?)?.map((decklist) => Card.fromJson(decklist)).toList() ?? [];
    username = parsedJson['username'] as String? ?? '';
    deckname = parsedJson['deckname'] as String? ?? '';
    public = parsedJson['public'] as bool? ?? false;
  }

   Map<String, dynamic> toJson() {
    return {
      'username': username,
      'deckname': deckname,
      'public': public,
      'cards': cards.map((card) => card.toJson()).toList(),
    };
   }
}