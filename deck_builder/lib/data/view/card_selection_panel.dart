import 'package:flutter/material.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;
import 'package:deck_builder/data/view/card_tile.dart';

class CardSelectionPanel extends StatelessWidget {
  final List<CardModel.Card> cards;
  final Map<String, int> decklist;
  final void Function(CardModel.Card) onAdd;
  final void Function(CardModel.Card) onRemove;
  final bool loading;
  final void Function(CardModel.Card) onView;

  // New properties for set selection
  final String selectedSet;
  final List<String> availableSets;
  final void Function(String) onSetSelected;

  const CardSelectionPanel({
    super.key,
    required this.cards,
    required this.decklist,
    required this.onAdd,
    required this.onRemove,
    required this.loading,
    required this.onView,
    required this.selectedSet,
    required this.availableSets,
    required this.onSetSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight, // bounded height for GridView
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final count = decklist[card.cardNo] ?? 0;

              return CardTile(
                card: card,
                count: count,
                onAdd: () => onAdd(card),
                onRemove: () => onRemove(card),
                onView: () => onView(card),
              );
            },
          ),
        );
      },
    );
  }
}
