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
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String identity, String password) async {
    final uri = Uri.parse('$pocketbase/api/collections/users/auth-with-password');

    final body = jsonEncode({
      'identity': identity,
      'password': password,
    });

    print('Attempting login with identity=$identity password=$password');
    print('POST $uri with body=${jsonEncode(body)}');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('Response: ${resp.statusCode} ${resp.body}');

    if (resp.statusCode != 200) {
      throw Exception('Login failed: ${resp.statusCode} ${resp.body}');
    }

    final data = jsonDecode(resp.body);
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

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return UserModel.User.fromJson(data);
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    final uri = Uri.parse('$pocketbase/api/collections/users/records/$id');
    final resp = await http.get(uri);
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to fetch user: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
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

    final jsonData = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (jsonData['items'] as List<dynamic>?) ?? [];
    return items
        .map((i) => CardModel.Card.fromPocketBaseJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<CardModel.Card> getCardByName(String name) async {
    final list = await getCards(perPage: 1, series: '', color: '', type: '', rarity: '', affinity: '');
    final card = list.firstWhere((c) => c.name == name, orElse: () => throw Exception('Card not found: $name'));
    return card;
  }

  // ---------------- DECKS ----------------
  Future<Deck> saveDeck(String userId, String deckname, bool isPublic, Map<String, int> decklist) async {
    final body = {
      'userId': userId,
      'deckname': deckname,
      'public': isPublic,
      'cards': decklist.entries.map((e) => {'cardname': e.key, 'quantity': e.value}).toList(),
    };
    final uri = Uri.parse('$pocketbase/api/collections/decks/records');
    final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (resp.statusCode != HttpStatus.ok && resp.statusCode != HttpStatus.created) {
      throw Exception('Failed to save deck: ${resp.statusCode} ${resp.body}');
    }
    return Deck.fromJson(jsonDecode(resp.body));
  }

  Future<Deck> updateDeck(String deckId, String deckname, bool isPublic, Map<String, int> decklist) async {
    final body = {
      'deckname': deckname,
      'public': isPublic,
      'cards': decklist.entries.map((e) => {'cardname': e.key, 'quantity': e.value}).toList(),
    };
    final uri = Uri.parse('$pocketbase/api/collections/decks/records/$deckId');
    final resp = await http.patch(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to update deck: ${resp.statusCode} ${resp.body}');
    }
    return Deck.fromJson(jsonDecode(resp.body));
  }

  Future<Deck> getDeckById(String deckId) async {
    final uri = Uri.parse('$pocketbase/api/collections/decks/records/$deckId');
    final resp = await http.get(uri);
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to fetch deck: ${resp.statusCode} ${resp.body}');
    }
    return Deck.fromJson(jsonDecode(resp.body));
  }

  Future<List<Deck>> getUserDecks(String userId, {int perPage = 100}) async {
    final uri = Uri.parse('$pocketbase/api/collections/decks/records')
        .replace(queryParameters: {'filter': 'userId="$userId"', 'perPage': '$perPage'});
    final resp = await http.get(uri);
    if (resp.statusCode != HttpStatus.ok) {
      throw Exception('Failed to fetch user decks: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
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
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
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
}
