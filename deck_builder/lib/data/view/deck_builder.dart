import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;
import 'package:deck_builder/data/model/deck.dart';
import 'package:deck_builder/data/util/api.dart';
import 'package:deck_builder/data/util/user_provider.dart';

class DeckBuilderPage extends StatefulWidget {
  final Deck? existingDeck;
  const DeckBuilderPage({super.key, this.existingDeck});

  @override
  DeckBuilderPageState createState() => DeckBuilderPageState();
}

class DeckBuilderPageState extends State<DeckBuilderPage> {
  final APIRunner api = APIRunner();

  List<CardModel.Card> allCards = [];
  Map<String, int> decklist = {}; // card name -> quantity
  Map<String, CardModel.Card> deckCardDetails = {};
  String deckname = '';
  bool isPublic = false;
  bool isEditable = true;
  bool loading = true;
  bool loadingCards = false;

  // Filters
  String selectedSet = '';
  String? selectedColor;
  String? selectedType;
  String? selectedRarity;
  String? selectedAffinity;

  List<String> availableSets = [];
  List<String> availableColors = [];
  List<String> availableTypes = [];
  List<String> availableRarities = [];
  List<String> availableAffinities = [];

  @override
  void initState() {
    super.initState();
    _initDeck();
  }

  Future<void> _initDeck() async {
    try {
      final sample = await api.getCards(perPage: 200);
      availableSets = sample.map((c) => c.series).toSet().toList();
      availableColors = sample.map((c) => c.color).toSet().toList();
      availableTypes = sample.map((c) => c.category).toSet().toList();
      availableRarities = sample.map((c) => c.rarity).toSet().toList();
      availableAffinities = sample.map((c) => c.attribute).toSet().toList();

      if (widget.existingDeck != null) {
        deckname = widget.existingDeck!.deckname;
        isPublic = widget.existingDeck!.public;

        final currentUser = context.read<UserProvider>().currentUser;
        final currentUserId = currentUser?.id ?? '';
        isEditable = widget.existingDeck!.userId == currentUserId;

        for (var card in widget.existingDeck!.cards) {
          final name = card['cardname'] ?? '';
          if (name.isNotEmpty) {
            decklist[name] = (decklist[name] ?? 0) + ((card['quantity'] ?? 1) as int);
          }
        }

        // Load initial set
        if (widget.existingDeck!.cards.isNotEmpty) {
          final firstName = widget.existingDeck!.cards.first['cardname'];
          if (firstName != null) {
            try {
              final firstCard = await api.getCardByName(firstName);
              selectedSet = firstCard.series;
            } catch (_) {}
          }
        }

        // Load all card details
        if (decklist.isNotEmpty) {
          final results = await Future.wait(decklist.keys.map(api.getCardByName));
          for (int i = 0; i < decklist.keys.length; i++) {
            deckCardDetails[decklist.keys.elementAt(i)] = results[i];
          }
        }
      }

      if (selectedSet.isNotEmpty) {
        await _loadCardsForSet(selectedSet);
      }

      setState(() => loading = false);
    } catch (e, st) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading deck builder: $e')));
      debugPrint(st.toString());
    }
  }

  Future<void> _loadCardsForSet(String set) async {
    setState(() => loadingCards = true);
    try {
      final cards = await api.getCards(series: set, perPage: 200);
      setState(() => allCards = cards);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load cards for $set: $e')));
    } finally {
      setState(() => loadingCards = false);
    }
  }

  List<CardModel.Card> get filteredCards {
    return allCards.where((c) {
      if (selectedSet.isNotEmpty && c.series != selectedSet) return false;
      if (selectedColor != null && c.color != selectedColor) return false;
      if (selectedType != null && c.category != selectedType) return false;
      if (selectedRarity != null && c.rarity != selectedRarity) return false;
      if (selectedAffinity != null && c.attribute != selectedAffinity) return false;
      return true;
    }).toList();
  }

  void addCard(CardModel.Card card) {
    if (!isEditable) return;
    final total = decklist.values.fold(0, (a, b) => a + b);
    if (total >= 50) return;
    final count = decklist[card.name] ?? 0;
    if (count >= 4) return;

    setState(() => decklist[card.name] = count + 1);
    if (!deckCardDetails.containsKey(card.name)) {
      api.getCardByName(card.name).then((c) {
        setState(() => deckCardDetails[card.name] = c);
      }).catchError((_) {});
    }
  }

  void removeCard(CardModel.Card card) {
    if (!isEditable) return;
    final count = decklist[card.name] ?? 0;
    if (count <= 0) return;
    setState(() {
      final newCount = count - 1;
      if (newCount <= 0) {
        decklist.remove(card.name);
        deckCardDetails.remove(card.name);
      } else {
        decklist[card.name] = newCount;
      }
    });
  }

  Future<void> saveDeck() async {
    if (!isEditable) return;
    final total = decklist.values.fold(0, (a, b) => a + b);
    if (deckname.isEmpty || total != 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck name required and must have 50 cards')),
      );
      return;
    }

    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('You must be logged in to save decks')));
      return;
    }

    try {
      bool exists = false;
      try {
        final existing = await api.getDeckById(widget.existingDeck?.id ?? '');
        exists = existing != null;
      } catch (_) {
        exists = false;
      }

      if (exists) {
        await api.updateDeck(currentUser.id, deckname, isPublic, decklist);
      } else {
        await api.saveDeck(currentUser.id, deckname, isPublic, decklist);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  void openFilterModal() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Filters'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildDropdown('Color', availableColors, selectedColor,
                  (v) => setState(() => selectedColor = v)),
              _buildDropdown('Type', availableTypes, selectedType,
                  (v) => setState(() => selectedType = v)),
              _buildDropdown('Rarity', availableRarities, selectedRarity,
                  (v) => setState(() => selectedRarity = v)),
              _buildDropdown('Affinity', availableAffinities, selectedAffinity,
                  (v) => setState(() => selectedAffinity = v)),
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
  }

  DropdownButton<String> _buildDropdown(
    String label,
    List<String> items,
    String? selected,
    Function(String?) onChanged,
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditable ? 'Deck Builder' : 'View Deck'),
        actions: [
          if (isEditable) IconButton(icon: const Icon(Icons.save), onPressed: saveDeck),
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: openFilterModal),
        ],
      ),
      body: Row(
        children: [
          _buildCardSelectionPanel(),
          _buildDeckPanel(),
        ],
      ),
    );
  }

  Widget _buildCardSelectionPanel() {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          if (selectedSet.isEmpty)
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: availableSets.map((s) {
                  return GestureDetector(
                    onTap: () async {
                      setState(() => selectedSet = s);
                      await _loadCardsForSet(s);
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(s, textAlign: TextAlign.center)),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (selectedSet.isNotEmpty)
            Expanded(
              child: loadingCards
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = filteredCards[index];
                        final count = decklist[card.name] ?? 0;
                        return _buildCardTile(card, count);
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardTile(CardModel.Card card, int count) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Expanded(
            child: card.image.isNotEmpty
                ? Image.network(card.image, fit: BoxFit.cover, width: double.infinity)
                : Container(color: Colors.grey[100]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(card.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: () => removeCard(card)),
              Text('$count'),
              IconButton(icon: const Icon(Icons.add), onPressed: () => addCard(card)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeckPanel() {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: TextEditingController(text: deckname),
              onChanged: (v) => setState(() => deckname = v),
              decoration: const InputDecoration(labelText: 'Deck Name'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Public'),
              Switch(
                value: isPublic,
                onChanged: isEditable ? (v) => setState(() => isPublic = v) : null,
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: decklist.entries.map((entry) {
                final card = deckCardDetails[entry.key] ??
                    CardModel.Card.empty(entry.key);
                return ListTile(
                  leading: card.image.isNotEmpty
                      ? Image.network(card.image, width: 60, fit: BoxFit.cover)
                      : const SizedBox(width: 60),
                  title: Text('${card.name} x${entry.value}'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
