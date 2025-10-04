import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:deck_builder/data/model/card.dart';

class APIRunner {
  final String apiKey = 'd8d05daadb1ee463df6dc55e4fa0b546bb5bf9c33351c98da1fe51d558c04b60';
  final String baseURL = 'https://apitcg.com/api/union-arena/cards?';

  final String backend = 'http://localhost:8080';

  Future<List<Card>?> runAPI(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'x-api-key': apiKey,
      },
    );

    if(response.statusCode == HttpStatus.ok) {
      final jsonData = jsonDecode(response.body);
      final cards = (jsonData['data'] as List).map((cardJson) => Card.fromJson(cardJson)).toList();
      return cards;
    } else {
      print('Request Failed: ${response.statusCode}');
      return null;
    }
  }

  Future<List<Card>?> getCards(String page) {
    final String cardlist = "${baseURL}limit=50&page=$page";
    return runAPI(cardlist);
  }
  Future<List<Card>?> searchCards(String page, String cardName) {
    final String cardlist = "${baseURL}name=$cardName&limit=50&page=$page";
    return runAPI(cardlist);
  }

  Future<void> saveDeck(String username, String deckname, bool public, List<Card> cards) async {
    final deckData = {
      'username': username,
      'deckname': deckname,
      'public': public,
      'decklist': cards.map((c) => c.toJson()).toList()
    };

    final response = await http.post(
      Uri.parse('$backend/decks'),
      headers: {'ContentType': 'application/json'},
      body: jsonEncode(deckData),
    );

    if(response.statusCode != HttpStatus.ok) { 
      print('Failed to save deck: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllDecks() async {
    final response = await http.get(Uri.parse('$backend/decks'));

    if(response.statusCode == HttpStatus.ok) { 
      final data = jsonDecode(response.body) as List;
      return data.map((d) => Map<String, dynamic>.from(d)).toList();
    }
    else {
      throw Exception('Failed to load public decks: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getPublicDecks() async {
    final response = await http.get(Uri.parse('$backend/decks/public'));
  
    if(response.statusCode == HttpStatus.ok) {
      final data = jsonDecode(response.body) as List;
      return data.map((d) => Map<String, dynamic>.from(d)).toList();
    }
    else {
      throw Exception('Failed to load public decks: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getUsersDecks(String username) async {
    final response = await http.get(Uri.parse('$backend/decks/user/$username'));

    if(response.statusCode == HttpStatus.ok) {
      final data = jsonDecode(response.body) as List;
      return data.map((d) => Map<String, dynamic>.from(d)).toList();
    }
    else {
      throw Exception('Failed to load public decks: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>?> updateUser(String oldUsername, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$backend/users/$oldUsername'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );

    if (response.statusCode == HttpStatus.ok) {
      final updatedUser = jsonDecode(response.body);
      print('User updated: $updatedUser');
      return updatedUser;
    } else {
      print('Failed to update user: ${response.body}');
      return null;
    }
  }

  Future<bool> updateDeck(String username, String deckname, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$backend/decks/$username/$deckname'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );

    if (response.statusCode == HttpStatus.ok) {
      print('Deck updated: ${response.body}');
      return true;
    } else {
      print('Failed to update deck: ${response.body}');
      return false;
    }
  }

  Future<bool> deleteDeck(String username, String deckname) async {
    final response = await http.delete(
      Uri.parse('$backend/decks/$username/$deckname'),
    );

    if (response.statusCode == HttpStatus.ok) {
      print('Deck deleted: ${response.body}');
      return true;
    } else {
      print('Failed to delete deck: ${response.body}');
      return false;
    }
  }

  Future<Map<String, dynamic>?> signup(String username, String password, String email) async {
    final response = await http.post(
      Uri.parse('$backend/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'email': email}),
    );

    if (response.statusCode == HttpStatus.ok) {
      return jsonDecode(response.body);
    } else {
      print('Signup failed: ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$backend/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == HttpStatus.ok) {
      return jsonDecode(response.body);
    } else {
      print('Login failed: ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final response = await http.get(Uri.parse('$backend/users/$username'));
    if (response.statusCode == HttpStatus.ok) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print('Get user failed: ${response.body}');
      return null;
    }
  }  
}