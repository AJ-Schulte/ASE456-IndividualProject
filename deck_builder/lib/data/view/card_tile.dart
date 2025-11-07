import 'package:flutter/material.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;

class CardTile extends StatelessWidget {
  final CardModel.Card card;
  final int count;
  final void Function()? onAdd;
  final void Function()? onRemove;
  final void Function()? onView;

  const CardTile({
    super.key,
    required this.card,
    required this.count,
    this.onAdd,
    this.onRemove,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Expanded(
              child: card.image.isNotEmpty
                  ? Image.network(card.image, fit: BoxFit.contain, width: double.infinity)
                  : Container(color: Colors.grey[100]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                card.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onAdd != null && onRemove != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: onRemove),
                  Text('$count'),
                  IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
                ],
              ),
            if (onView != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: onView,
                  child: const Text('View'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
