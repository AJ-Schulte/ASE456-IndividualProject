import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/model/card.dart' as CardModel;
import 'package:deck_builder/data/model/deck.dart';
import 'package:deck_builder/data/util/api.dart';
import 'package:deck_builder/data/util/user_provider.dart';
import 'package:deck_builder/data/util/deck_utils.dart';
import 'package:deck_builder/data/util/deck_filters.dart';
import 'package:deck_builder/data/view/card_selection_panel.dart';
import 'package:deck_builder/data/view/deck_panel.dart';

class DeckBuilderPage extends StatefulWidget {
  final Deck? existingDeck;
  const DeckBuilderPage({super.key, this.existingDeck});

  @override
  DeckBuilderPageState createState() => DeckBuilderPageState();
}

class DeckBuilderPageState extends State<DeckBuilderPage> {
  final APIRunner api = APIRunner();

  Map<String, String> seriesMap = {};
  List<CardModel.Card> allCards = [];
  Map<String, int> decklist = {};
  Map<String, CardModel.Card> deckCardDetails = {};
  String deckname = '';
  bool isPublic = false;
  bool isEditable = true;
  bool loading = true;
  bool loadingCards = false;

  String selectedSet = '';
  String? selectedColor;
  String? selectedType;
  String? selectedRarity;
  String? selectedAffinity;

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
      seriesMap = await api.getAllSeries();
      final filters = await api.getDeckFilters();
      availableColors = filters['colors']!;
      availableTypes = filters['types']!;
      availableRarities = filters['rarities']!;
      availableAffinities = filters['affinities']!;

      if (widget.existingDeck != null) {
        deckname = widget.existingDeck!.deckname;
        isPublic = widget.existingDeck!.public;
        final currentUser = context.read<UserProvider>().currentUser;
        isEditable = widget.existingDeck!.userId == currentUser?.id;

        for (var card in widget.existingDeck!.cards) {
          final cardNo = card['cardNo'] ?? '';
          if (cardNo.isNotEmpty) decklist[cardNo] = (decklist[cardNo] ?? 0) + ((card['quantity'] ?? 1) as int);
        }

        if (decklist.isNotEmpty) {
          final firstCardNo = widget.existingDeck!.cards.first['cardNo'];
          if (firstCardNo != null) {
            try {
              final firstCard = await api.getCardByCardNo(firstCardNo);
              selectedSet = firstCard.series;
            } catch (_) {}
          }
          final results = await Future.wait(decklist.keys.map(api.getCardByCardNo));
          for (int i = 0; i < decklist.keys.length; i++) {
            deckCardDetails[decklist.keys.elementAt(i)] = results[i];
          }
        }
      }

      if (selectedSet.isNotEmpty) await _loadCardsForSet(selectedSet);

      setState(() => loading = false);
    } catch (e, st) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading deck builder: $e')));
      debugPrint(st.toString());
    }
  }

  Future<void> _loadCardsForSet(String set) async {
    setState(() => loadingCards = true);
    try {
      final cards = await api.getCards(series: set, perPage: 200);
      setState(() => allCards = cards);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cards for set: $e')));
    } finally {
      setState(() => loadingCards = false);
    }
  }

  List<CardModel.Card> get filteredCards {
    return allCards.where((c) {
      if (selectedColor != null && c.color != selectedColor) return false;
      if (selectedType != null && c.category != selectedType) return false;
      if (selectedRarity != null && c.rarity != selectedRarity) return false;
      if (selectedAffinity != null && c.attribute != selectedAffinity) return false;
      return true;
    }).toList();
  }

  void _viewCard(CardModel.Card card) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.image.isNotEmpty)
                  Image.network(
                    card.image,
                    width: 160,
                    height: 230,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Card No: ${card.cardNo}'),
                      Text('Set: ${seriesMap[card.series] ?? card.series}'),
                      Text('Color: ${card.color}'),
                      Text('Rarity: ${card.rarity}'),
                      Text('Type: ${card.category}'),
                      Text('Power (BP): ${card.bp}'),
                      Text('AP Cost: ${card.ap}'),
                      Text('Energy Cost: ${card.requiredEnergy}'),
                      Text('Energy Gen: ${card.generatedEnergy}'),
                      const SizedBox(height: 8),
                      Text('Effect:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(card.effect),
                      if (card.trigger.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Trigger:', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(card.trigger),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditable ? 'Deck Builder' : 'View Deck'),
        actions: [
          if (isEditable)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => saveDeck(decklist, deckCardDetails, deckname, isPublic, api, context, widget.existingDeck),
            ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => showDeckFilters(
              context: context,
              colors: availableColors,
              types: availableTypes,
              rarities: availableRarities,
              affinities: availableAffinities,
              selectedColor: selectedColor,
              selectedType: selectedType,
              selectedRarity: selectedRarity,
              selectedAffinity: selectedAffinity,
              onColorChanged: (v) => setState(() => selectedColor = v),
              onTypeChanged: (v) => setState(() => selectedType = v),
              onRarityChanged: (v) => setState(() => selectedRarity = v),
              onAffinityChanged: (v) => setState(() => selectedAffinity = v),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: Series + Card Selection Panel (50% width)
          Expanded(
            flex: 1,
            child: selectedSet.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: seriesMap.entries.map((e) {
                      final seriesKey = e.key;
                      final seriesName = e.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                          onPressed: () async {
                            setState(() => selectedSet = seriesKey);
                            await _loadCardsForSet(seriesKey);
                          },
                          child: Text(seriesName, textAlign: TextAlign.center),
                        ),
                      );
                    }).toList(),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min, // prevent unbounded height error
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => selectedSet = ''),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Series'),
                        ),
                      ),
                      Flexible(
                        child: CardSelectionPanel(
                          cards: filteredCards,
                          decklist: decklist,
                          onAdd: (c) => addCard(decklist, deckCardDetails, c, api, setState),
                          onRemove: (c) => removeCard(decklist, deckCardDetails, c, api, setState),
                          loading: loadingCards,
                          selectedSet: selectedSet,
                          availableSets: const [],
                          onSetSelected: (_) {},
                          onView: _viewCard,
                        ),
                      ),
                    ],
                  ),
          ),

          // Right: Deck Panel (50% width)
          Expanded(
            flex: 1,
            child: DeckPanel(
              deckname: deckname,
              onDeckNameChanged: (v) => setState(() => deckname = v),
              isPublic: isPublic,
              onPublicChanged: isEditable ? (v) => setState(() => isPublic = v) : (_) {},
              decklist: decklist,
              deckCardDetails: deckCardDetails,
              onView: _viewCard,
              onAdd: (card) => addCard(decklist, deckCardDetails, card, api, setState),
              onRemove: (card) => removeCard(decklist, deckCardDetails, card, api, setState),
            ),
          ),
        ],
      ),
    );
  }
}
