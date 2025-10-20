import 'package:flutter/material.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;
import 'package:deck_builder/data/model/deck.dart';
import 'package:deck_builder/data/util/api.dart';
import 'package:deck_builder/data/util/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

Future<void> addCard(
  Map<String, int> decklist,
  Map<String, CardModel.Card> deckCardDetails,
  CardModel.Card card,
  APIRunner api,
  void Function(void Function()) setState,
) async {
  final count = decklist[card.cardNo] ?? 0;
  if (count >= 4) return;
  setState(() {
    decklist[card.cardNo] = count + 1;
    deckCardDetails[card.cardNo] = card;
  });
}

void removeCard(
  Map<String, int> decklist,
  Map<String, CardModel.Card> deckCardDetails,
  CardModel.Card card,
  APIRunner api,
  void Function(void Function()) setState,
) {
  final count = decklist[card.cardNo] ?? 0;
  if (count <= 0) return;
  setState(() {
    final newCount = count - 1;
    if (newCount <= 0) {
      decklist.remove(card.cardNo);
      deckCardDetails.remove(card.cardNo);
    } else {
      decklist[card.cardNo] = newCount;
    }
  });
}

Future<void> saveDeck(
  Map<String, int> decklist,
  Map<String, CardModel.Card> deckCardDetails,
  String deckname,
  bool isPublic,
  APIRunner api,
  BuildContext context,
  Deck? existingDeck,
) async {
  final normalCards = deckCardDetails.values
      .where((card) => !(card.category.toLowerCase().contains('action point')))
      .toList();
  final apCards = deckCardDetails.values
      .where((card) => card.category.toLowerCase().contains('action point'))
      .toList();

  final total = normalCards.fold<int>(0, (a, c) => a + (decklist[c.cardNo] ?? 0));
  final totalAp = apCards.fold<int>(0, (a, c) => a + (decklist[c.cardNo] ?? 0));

  if (deckname.isEmpty || total != 50 || totalAp > 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deck must have a name, 50 cards (excluding AP cards), and at most 3 Action Points',
        ),
      ),
    );
    return;
  }

  final currentUser = context.read<UserProvider>().currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You must be logged in to save decks')),
    );
    return;
  }

  try {
    bool exists = false;
    if (existingDeck != null) {
      try {
        final existing = await api.getDeckById(existingDeck.id);
        exists = existing != null;
      } catch (_) {
        exists = false;
      }
    }

    final deckToSave = Map<String, int>.from(decklist.map((key, value) =>
        MapEntry(utf8.encode(key).toString(), value)));

    final deckCardDetailsUtf8 = Map<String, CardModel.Card>.from(deckCardDetails.map((key, value) =>
        MapEntry(utf8.encode(key).toString(), value)));

    if (exists) {
      await api.updateDeck(existingDeck!.id, deckname, isPublic, deckToSave, deckCardDetailsUtf8);
    } else {
      await api.saveDeck(currentUser.id, deckname, isPublic, deckToSave, deckCardDetailsUtf8);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deck saved successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Save failed: $e')),
    );
  }
}
