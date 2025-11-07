import 'package:flutter/material.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;
import 'package:deck_builder/data/model/deck.dart';
import 'package:deck_builder/data/util/api.dart';
import 'package:deck_builder/data/util/user_provider.dart';
import 'package:provider/provider.dart';

Future<void> addCard(
  Map<String, int> decklist,
  Map<String, CardModel.Card> deckCardDetails,
  CardModel.Card card,
  APIRunner api,
  void Function(void Function()) setState,
) async {
  final count = decklist[card.cardNo] ?? 0;
  if (count >= 4) return; // general per-card limit
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
  // --- VALIDATION ---

  int totalMain = 0;
  int totalAP = 0;
  Map<String, int> triggerCount = {};

  decklist.forEach((cardNo, qty) {
    final card = deckCardDetails[cardNo];
    if (card == null) return;

    final type = card.category.toLowerCase();

    if (type.contains('action point')) {
      totalAP += qty;
    } else {
      totalMain += qty;
    }

    if (card.trigger.isNotEmpty) {
      final triggerKey = card.trigger.trim().toLowerCase();
      triggerCount[triggerKey] = (triggerCount[triggerKey] ?? 0) + qty;
    }
  });

  // --- Deck name & basic validation ---
  if (deckname.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deck must have a name.')),
    );
    return;
  }

  if (totalMain != 50) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Main deck must contain exactly 50 cards (currently $totalMain).',
        ),
      ),
    );
    return;
  }

  if (totalAP > 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You can only include up to 3 Action Point cards.'),
      ),
    );
    return;
  }

  // --- Trigger validation ---
  triggerCount.forEach((trigger, count) {
    if ((trigger.contains('color') ||
            trigger.contains('final') ||
            trigger.contains('special')) &&
        count > 4) {
      throw Exception(
          'Too many cards with trigger "$trigger" (max 4, found $count).');
    }
  });

  // --- Authentication ---
  final currentUser = context.read<UserProvider>().currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You must be logged in to save decks.')),
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

    // ✅ FIXED: no UTF-8 encoding — use real cardNo
    final deckToSave = Map<String, int>.from(decklist);
    final deckCardDetailsToSave =
        Map<String, CardModel.Card>.from(deckCardDetails);

    if (exists) {
      await api.updateDeck(
          existingDeck!.id, deckname, isPublic, deckToSave, deckCardDetailsToSave);
    } else {
      await api.saveDeck(
          currentUser.id, deckname, isPublic, deckToSave, deckCardDetailsToSave);
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
