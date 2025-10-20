import 'package:flutter/material.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;
import 'package:deck_builder/data/view/card_tile.dart';

class DeckPanel extends StatefulWidget {
  final String deckname;
  final void Function(String) onDeckNameChanged;
  final bool isPublic;
  final void Function(bool) onPublicChanged;
  final Map<String, int> decklist;
  final Map<String, CardModel.Card> deckCardDetails;
  final void Function(CardModel.Card) onView;
  final void Function(CardModel.Card)? onAdd;
  final void Function(CardModel.Card)? onRemove;

  const DeckPanel({
    super.key,
    required this.deckname,
    required this.onDeckNameChanged,
    required this.isPublic,
    required this.onPublicChanged,
    required this.decklist,
    required this.deckCardDetails,
    required this.onView,
    this.onAdd,
    this.onRemove,
  });

  @override
  _DeckPanelState createState() => _DeckPanelState();
}

class _DeckPanelState extends State<DeckPanel> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.deckname);
  }

  @override
  void didUpdateWidget(covariant DeckPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deckname != _controller.text) {
      _controller.text = widget.deckname;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get totalCards {
    int total = 0;
    widget.decklist.forEach((cardNo, quantity) {
      final card = widget.deckCardDetails[cardNo];
      if (card != null && card.category.toLowerCase() != 'action point') {
        total += quantity;
      }
    });
    return total;
  }

  int get totalAPCards {
    int total = 0;
    widget.decklist.forEach((cardNo, quantity) {
      final card = widget.deckCardDetails[cardNo];
      if (card != null && card.category.toLowerCase() == 'action point') {
        total += quantity;
      }
    });
    return total;
  }

  int countTriggerType(String type) {
    int total = 0;
    widget.decklist.forEach((cardNo, quantity) {
      final card = widget.deckCardDetails[cardNo];
      if (card != null &&
          card.trigger.toLowerCase().contains(type.toLowerCase())) {
        total += quantity;
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.deckCardDetails.values.toList();

    final colorTriggers = countTriggerType("color");
    final finalTriggers = countTriggerType("final");
    final specialTriggers = countTriggerType("special");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deck name input
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _controller,
            onChanged: widget.onDeckNameChanged,
            decoration: const InputDecoration(labelText: 'Deck Name'),
          ),
        ),

        // Public/private toggle
        SwitchListTile(
          title: const Text('Public'),
          value: widget.isPublic,
          onChanged: widget.onPublicChanged,
        ),

        // Stats bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Cards: $totalCards / 50'),
              Text('AP Cards: $totalAPCards / 3'),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('COLOR Triggers: $colorTriggers'),
                  Text('FINAL Triggers: $finalTriggers'),
                  Text('SPECIAL Triggers: $specialTriggers'),
                ],
              ),
            ],
          ),
        ),

        // Card grid
        Expanded(
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
              final count = widget.decklist[card.cardNo] ?? 0;

              return CardTile(
                card: card,
                count: count,
                onAdd: widget.onAdd != null ? () => widget.onAdd!(card) : null,
                onRemove: widget.onRemove != null ? () => widget.onRemove!(card) : null,
                onView: () => widget.onView(card),
              );
            },
          ),
        ),
      ],
    );
  }
}
