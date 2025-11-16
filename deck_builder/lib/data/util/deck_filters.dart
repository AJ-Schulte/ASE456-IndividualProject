import 'package:flutter/material.dart';

Future<void> showDeckFilters({
  required BuildContext context,
  required List<String> colors,
  required List<String> types,
  required List<String> rarities,
  required List<String> affinities,
  String? selectedColor,
  String? selectedType,
  String? selectedRarity,
  String? selectedAffinity,
  required void Function(String?) onColorChanged,
  required void Function(String?) onTypeChanged,
  required void Function(String?) onRarityChanged,
  required void Function(String?) onAffinityChanged,
  required bool hideAlts,
  required bool hidePromos, // unified promo/release
  required void Function(bool) onHideAltsChanged,
  required void Function(bool) onHidePromosChanged,
}) {
  Widget buildLabeledDropdown(
    String label,
    List<String> items,
    String? selected,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              )),
          const SizedBox(height: 4),
          DropdownButton<String>(
            isExpanded: true,
            value: selected,
            hint: const Text("Any"),
            items: [null, ...items]
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c ?? 'Any'),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  return showDialog(
    context: context,
    builder: (context) {
      bool localHideAlts = hideAlts;
      bool localHidePromos = hidePromos;

      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filters'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildLabeledDropdown('Color', colors, selectedColor, onColorChanged),
                buildLabeledDropdown('Type', types, selectedType, onTypeChanged),
                buildLabeledDropdown('Rarity', rarities, selectedRarity, onRarityChanged),
                buildLabeledDropdown('Affinity', affinities, selectedAffinity, onAffinityChanged),

                const SizedBox(height: 12),

                SwitchListTile(
                  title: const Text('Hide Alternate Arts'),
                  value: localHideAlts,
                  onChanged: (v) {
                    setState(() => localHideAlts = v);
                    onHideAltsChanged(v);
                  },
                ),

                SwitchListTile(
                  title: const Text('Hide Promo / Release Event Cards'),
                  value: localHidePromos,
                  onChanged: (v) {
                    setState(() => localHidePromos = v);
                    onHidePromosChanged(v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    },
  );
}
