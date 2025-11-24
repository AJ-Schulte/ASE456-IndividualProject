import 'package:flutter_test/flutter_test.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;
import 'package:deck_builder/data/model/deck.dart' as DeckModel;
import 'package:deck_builder/data/model/user.dart' as UserModel;

void main() {
  group('Model parsing tests', () {
    test('Card.fromPocketBaseJson handles nested record and types', () {
      final json = {
        'record': {
          'id': 'c1',
          'cardNo': 'C1',
          'name': 'Fireball',
          'seriesName': 'S',
          'series': 'S1',
          'categoryData': 'Unit',
          'color': 'Red',
          'apData': 1,
          'bpData': 100,
          'effectData': 'Boom',
          'triggerData': 'color',
          'attributeData': 'Fire',
          'rarity': 'Rare',
          'image': '',
          'needEnergyData': 0,
          'generatedEnergyData': 0,
          'keywords': '',
          'marketPrice': 1.23,
          'abbreviation': 'FB',
        }
      };

      final c = CardModel.Card.fromPocketBaseJson(json);
      expect(c.id, 'c1');
      expect(c.ap, 1);
      expect(c.bp, 100);
      expect(c.name, 'Fireball');
      expect(c.trigger, 'color');
    });

    test('Deck.fromJson and toJson round trip', () {
      final deck = DeckModel.Deck(
        id: 'd1',
        userId: 'u1',
        deckname: 'MyDeck',
        public: true,
        cards: [
          {'cardNo': 'C1', 'quantity': 2},
        ],
      );

      final json = deck.toJson();
      final parsed = DeckModel.Deck.fromJson(json);
      expect(parsed.id, 'd1');
      expect(parsed.deckname, 'MyDeck');
      expect(parsed.cards.length, 1);
      expect(parsed.cards.first['cardNo'], 'C1');
    });

    test('User.fromJson and toJson', () {
      final user = UserModel.User(id: 'u1', username: 'bob', email: 'b@e');
      final json = user.toJson();
      final parsed = UserModel.User.fromJson(json);
      expect(parsed.id, 'u1');
      expect(parsed.username, 'bob');
      expect(parsed.email, 'b@e');
    });
  });
}

