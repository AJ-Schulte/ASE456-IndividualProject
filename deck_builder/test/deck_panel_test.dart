import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deck_builder/data/view/deck_panel.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;

void main() {
  group('DeckPanel tests', () {
    final cardA = CardModel.Card(
      id: '1',
      cardNo: 'A1',
      name: 'Alpha',
      seriesName: '',
      series: '',
      category: 'Unit',
      color: '',
      ap: 0,
      bp: 100,
      effect: '',
      trigger: 'color',
      attribute: '',
      rarity: '',
      image: '',
      requiredEnergy: 0,
      generatedEnergy: 0,
      keywords: '',
      marketPrice: 0.0,
      abbreviation: '',
    );

    final cardAP = CardModel.Card(
      id: '2',
      cardNo: 'AP1',
      name: 'ActionPoint',
      seriesName: '',
      series: '',
      category: 'Action Point',
      color: '',
      ap: 1,
      bp: 0,
      effect: '',
      trigger: '',
      attribute: '',
      rarity: '',
      image: '',
      requiredEnergy: 0,
      generatedEnergy: 0,
      keywords: '',
      marketPrice: 0.0,
      abbreviation: '',
    );

    testWidgets('Stats and trigger counts are calculated correctly', (WidgetTester tester) async {
      final decklist = {'A1': 50, 'AP1': 2};
      final deckCardDetails = {'A1': cardA, 'AP1': cardAP};

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeckPanel(
            deckname: 'My Deck',
            onDeckNameChanged: (_) {},
            isPublic: false,
            onPublicChanged: (_) {},
            decklist: decklist,
            deckCardDetails: deckCardDetails,
            onView: (_) {},
            onAdd: (_) {},
            onRemove: (_) {},
          ),
        ),
      ));

      // Should display Main Deck: 50 / 50 and AP Cards: 2 / 3
      expect(find.textContaining('Main Deck: 50 / 50'), findsOneWidget);
      expect(find.textContaining('AP Cards: 2 / 3'), findsOneWidget);

      // Trigger count (color) should be 50 because cardA has trigger 'color'
      expect(find.textContaining('COLOR Triggers: 50'), findsOneWidget);
    });

    testWidgets('Add/remove buttons call callbacks', (WidgetTester tester) async {
      int addCalls = 0;
      int removeCalls = 0;
      final decklist = {'A1': 1};
      final deckCardDetails = {'A1': cardA};

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeckPanel(
            deckname: 'My Deck',
            onDeckNameChanged: (_) {},
            isPublic: false,
            onPublicChanged: (_) {},
            decklist: Map.from(decklist),
            deckCardDetails: Map.from(deckCardDetails),
            onView: (_) {},
            onAdd: (_) { addCalls++; },
            onRemove: (_) { removeCalls++; },
          ),
        ),
      ));

      final addBtn = find.byIcon(Icons.add);
      final removeBtn = find.byIcon(Icons.remove);

      expect(addBtn, findsOneWidget);
      expect(removeBtn, findsOneWidget);

      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      expect(addCalls, 1);
      expect(removeCalls, 1);
    });
  });
}

