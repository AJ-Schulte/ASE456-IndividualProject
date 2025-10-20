import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:deck_builder/data/model/card.dart' as CardModel;
import 'package:deck_builder/data/model/deck.dart';
import 'package:deck_builder/data/model/user.dart' as UserModel;

const String POCKETBASE_URL = String.fromEnvironment(
  'POCKETBASE_URL',
  defaultValue: 'http://127.0.0.1:8090',
);

class APIRunner {
  final String pocketbase = POCKETBASE_URL;

  String _encode(String s) => Uri.encodeComponent(s);

  // ---------------- USERS ----------------
  Future<Map<String, dynamic>> signup(
      String username, String email, String password) async {
    final uri = Uri.parse('$pocketbase/api/collections/users/records');
    final body = {
      'username': username,
      'email': email,
      'password': password,
      'passwordConfirm': password,
    };
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (resp.statusCode != HttpStatus.ok && resp.statusCode != HttpStatus.created) {
      throw Exception('Signup failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String identity, String password) async {
    final uri = Uri.parse('$pocketbase/api/collections/users/auth-with-password');
    final body = jsonEncode({'identity': identity, 'password': password});

    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: body);

    if (resp.statusCode != 200) {
      throw Exception('Login failed: ${resp.statusCode} ${resp.body}');
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    if (data is! Map<String, dynamic> || !data.containsKey('record')) {
      throw Exception('Unexpected response format: ${resp.body}');
    }

    return data;
  }

  Future<UserModel.User> updateUser(String userId, Map<String, dynamic> updates) async {
    if (updates.containsKey('password') && !updates.containsKey('passwordConfirm')) {
      updates['passwordConfirm'] = updates['password'];
    }
    final uri = Uri.parse('$pocketbase/api/collections/users/records/$userId');
    final resp = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to update user: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return UserModel.User.fromJson(data);
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    final uri = Uri.parse('$pocketbase/api/collections/users/records/$id');
    final resp = await http.get(uri);
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to fetch user: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  }

  // ---------------- CARDS ----------------
  Future<List<CardModel.Card>> getCards({
    int page = 1,
    int perPage = 50,
    String series = '',
    String color = '',
    String type = '',
    String rarity = '',
    String affinity = '',
  }) async {
    final q = <String, String>{
      'page': page.toString(),
      'perPage': perPage.toString(),
    };

    final filters = <String>[];
    if (series.isNotEmpty) filters.add('series="$series"');
    if (color.isNotEmpty) filters.add('color="$color"');
    if (type.isNotEmpty) filters.add('category="$type"');
    if (rarity.isNotEmpty) filters.add('rarity="$rarity"');
    if (affinity.isNotEmpty) filters.add('attribute="$affinity"');
    if (filters.isNotEmpty) q['filter'] = filters.join(' && ');

    final uri = Uri.parse('$pocketbase/api/collections/cards/records').replace(queryParameters: q);
    final resp = await http.get(uri);
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to fetch cards: ${resp.statusCode} ${resp.body}');
    }

    final jsonData = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final items = (jsonData['items'] as List<dynamic>?) ?? [];
    return items.map((i) => CardModel.Card.fromPocketBaseJson(i as Map<String, dynamic>)).toList();
  }

  Future<CardModel.Card> getCardByName(String name) async {
    final list = await getCards(perPage: 1);
    final card = list.firstWhere((c) => c.name == name, orElse: () => throw Exception('Card not found: $name'));
    return card;
  }

  Future<CardModel.Card> getCardByCardNo(String cardNo) async {
    try {
      final query = {
        'filter': 'cardNo="$cardNo"',
        'perPage': '1',
      };
      final uri = Uri.parse('$pocketbase/api/collections/cards/records').replace(queryParameters: query);
      final resp = await http.get(uri);

      if (resp.statusCode != HttpStatus.ok) {
        throw Exception('Failed to fetch card by cardNo: ${resp.statusCode} ${resp.body}');
      }

      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];
      if (items.isEmpty) {
        throw Exception('Card not found: $cardNo');
      }

      return CardModel.Card.fromPocketBaseJson(items.first as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch card by cardNo: $e');
    }
  }

  Future<Map<String, String>> getAllSeries({int perPage = 200}) async {
    int page = 1;
    bool hasMore = true;
    final seriesMap = <String, String>{};

    while (hasMore) {
      final cards = await getCards(page: page, perPage: perPage);
      for (var c in cards) {
        if (!seriesMap.containsKey(c.series)) {
          seriesMap[c.series] = c.seriesName;
        }
      }
      hasMore = cards.length == perPage;
      page++;
    }

    return seriesMap;
  }

  Future<Map<String, List<String>>> getDeckFilters() async {
    int page = 1;
    const perPage = 200;
    bool more = true;

    final colors = <String>{};
    final types = <String>{};
    final rarities = <String>{};
    final affinities = <String>{};

    while (more) {
      final uri = Uri.parse('$pocketbase/api/collections/cards/records')
          .replace(queryParameters: {'page': '$page', 'perPage': '$perPage'});
      final resp = await http.get(uri);
      if (resp.statusCode != HttpStatus.ok) {
        throw Exception('Failed to fetch cards for filters: ${resp.statusCode} ${resp.body}');
      }

      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];

      for (var item in items) {
        final map = item as Map<String, dynamic>;
        if (map['color'] != null) colors.add(map['color'].toString());
        if (map['categoryData'] != null) types.add(map['categoryData'].toString());
        if (map['rarity'] != null) rarities.add(map['rarity'].toString());
        if (map['attributeData'] != null) affinities.add(map['attributeData'].toString());
      }

      more = items.length == perPage;
      page++;
    }

    return {
      'colors': colors.toList()..sort(),
      'types': types.toList()..sort(),
      'rarities': rarities.toList()..sort(),
      'affinities': affinities.toList()..sort(),
    };
  }

  // ---------------- DECKS ----------------
   Future<Deck> saveDeck(
    String userId,
    String deckname,
    bool isPublic,
    Map<String, int> decklist,
    Map<String, CardModel.Card> deckCardDetails,
  ) async {
    // Validate deck rules before saving
    _validateDeck(decklist, deckCardDetails);

    final body = {
      'userId': userId,
      'deckName': deckname,
      'public': isPublic,
      'cards': decklist.entries
          .map((e) => {'cardname': e.key, 'quantity': e.value})
          .toList(),
    };

    final uri = Uri.parse('$pocketbase/api/collections/decks/records');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != HttpStatus.ok &&
        resp.statusCode != HttpStatus.created) {
      throw Exception('Failed to save deck: ${resp.statusCode} ${resp.body}');
    }

    return Deck.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
  }

  Future<Deck> updateDeck(
    String deckId,
    String deckname,
    bool isPublic,
    Map<String, int> decklist,
    Map<String, CardModel.Card> deckCardDetails,
  ) async {
    // Validate deck rules before updating
    _validateDeck(decklist, deckCardDetails);

    final body = {
      'deckname': deckname,
      'public': isPublic,
      'cards': decklist.entries
          .map((e) => {'cardname': e.key, 'quantity': e.value})
          .toList(),
    };

    final uri =
        Uri.parse('$pocketbase/api/collections/decks/records/$deckId');
    final resp = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to update deck: ${resp.statusCode} ${resp.body}');
    }

    return Deck.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
  }

  Future<Deck> getDeckById(String deckId) async {
    final uri = Uri.parse('$pocketbase/api/collections/decks/records/$deckId');
    final resp = await http.get(uri);
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to fetch deck: ${resp.statusCode} ${resp.body}');
    }
    return Deck.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
  }

  Future<List<Deck>> getUserDecks(String userId, {int perPage = 100}) async {
    final uri = Uri.parse('$pocketbase/api/collections/decks/records')
        .replace(queryParameters: {'filter': 'userId="$userId"', 'perPage': '$perPage'});
    final resp = await http.get(uri);
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to fetch user decks: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? [];
    return items.map((d) => Deck.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<List<Deck>> getPublicDecks({int perPage = 100}) async {
    final uri = Uri.parse('$pocketbase/api/collections/decks/records')
        .replace(queryParameters: {'filter': 'public=true', 'perPage': '$perPage'});
    final resp = await http.get(uri);
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to fetch public decks: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? [];
    return items.map((d) => Deck.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<void> deleteDeck(String deckId) async {
    final uri = Uri.parse('$pocketbase/api/collections/decks/records/$deckId');
    final resp = await http.delete(uri);
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to delete deck: ${resp.statusCode} ${resp.body}');
    }
  }

  // ---------------- VALIDATION ----------------
  void _validateDeck(
    Map<String, int> decklist,
    Map<String, CardModel.Card> deckCardDetails,
  ) {
    int totalCards = 0;
    int totalAP = 0;

    decklist.forEach((cardNo, qty) {
      final card = deckCardDetails[cardNo];
      if (card != null) {
        if (card.category.toLowerCase() == 'action point') {
          totalAP += qty;
        } else {
          totalCards += qty;
        }
      }
    });

    if (totalCards > 50) {
      throw Exception('Deck has $totalCards cards. Max allowed is 50 (excluding AP cards).');
    }
    if (totalAP > 3) {
      throw Exception('Deck has $totalAP Action Point cards. Max allowed is 3.');
    }
  }
}
