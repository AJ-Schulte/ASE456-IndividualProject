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
  DropdownButton<String> buildDropdown(
    String label,
    List<String> items,
    String? selected,
    void Function(String?) onChanged,
  ) {
    return DropdownButton<String>(
      hint: Text(label),
      isExpanded: true,
      value: selected,
      items: [null, ...items]
          .map((c) => DropdownMenuItem(value: c, child: Text(c ?? 'Any')))
          .toList(),
      onChanged: onChanged,
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
                buildDropdown('Color', colors, selectedColor, onColorChanged),
                buildDropdown('Type', types, selectedType, onTypeChanged),
                buildDropdown('Rarity', rarities, selectedRarity, onRarityChanged),
                buildDropdown('Affinity', affinities, selectedAffinity, onAffinityChanged),
                const SizedBox(height: 16),
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
