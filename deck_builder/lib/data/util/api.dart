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
}