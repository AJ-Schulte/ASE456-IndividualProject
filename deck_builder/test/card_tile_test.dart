import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deck_builder/data/view/card_selection_panel.dart';
import 'package:deck_builder/data/view/card_tile.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;

void main() {
  group('CardTile & CardSelectionPanel widget tests', () {
    final sampleCard = CardModel.Card(
      id: '1',
      cardNo: 'C001',
      name: 'Test Card',
      seriesName: 'Series A',
      series: 'S1',
      category: 'Unit',
      color: 'Red',
      ap: 1,
      bp: 100,
      effect: 'Do something',
      trigger: '',
      attribute: 'Fire',
      rarity: 'Rare',
      image: '',
      requiredEnergy: 0,
      generatedEnergy: 0,
      keywords: '',
      marketPrice: 0.0,
      abbreviation: '',
    );

    testWidgets('CardTile shows name and count and buttons call callbacks', (WidgetTester tester) async {
      int addCalls = 0;
      int removeCalls = 0;
      int viewCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: CardTile(
              card: sampleCard,
              count: 2,
              onAdd: () { addCalls++; },
              onRemove: () { removeCalls++; },
              onView: () { viewCalls++; },
            ),
          ),
        ),
      );

      expect(find.text('Test Card'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Tap add and remove buttons
      final addBtn = find.byIcon(Icons.add);
      final removeBtn = find.byIcon(Icons.remove);
      final viewBtn = find.widgetWithText(ElevatedButton, 'View');

      expect(addBtn, findsOneWidget);
      expect(removeBtn, findsOneWidget);
      expect(viewBtn, findsOneWidget);

      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();
      await tester.tap(viewBtn);
      await tester.pumpAndSettle();

      expect(addCalls, 1);
      expect(removeCalls, 1);
      expect(viewCalls, 1);
    });

    testWidgets('CardSelectionPanel displays grid of cards and forwards callbacks', (WidgetTester tester) async {
      int addCalls = 0;
      int removeCalls = 0;
      int viewCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardSelectionPanel(
              cards: [sampleCard, sampleCard],
              decklist: {'C001': 1},
              onAdd: (c) { addCalls++; },
              onRemove: (c) { removeCalls++; },
              onView: (c) { viewCalls++; },
              loading: false,
              selectedSet: 'S1',
              availableSets: ['S1'],
              onSetSelected: (_) {},
            ),
          ),
        ),
      );

      // Grid should render two tiles
      expect(find.byType(CardTile), findsNWidgets(2));

      // Tap first tile's view button
      final viewBtns = find.widgetWithText(ElevatedButton, 'View');
      expect(viewBtns, findsWidgets);
      await tester.tap(viewBtns.first);
      await tester.pumpAndSettle();
      expect(viewCalls, 1);
    });
  });
}

