import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:deck_builder/data/model/card.dart';

class APIRunner {
  final String apiKey = 'API KEY';
  final String baseURL = 'https://apitcg.com/api/union-arena/cards?';

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
}