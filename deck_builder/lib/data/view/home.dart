import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/util/api.dart';
import 'package:deck_builder/data/model/deck.dart';
import 'package:deck_builder/data/util/user_provider.dart';
import 'deck_builder.dart';
import 'top_nav_appbar.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final APIRunner api = APIRunner();
  List<Deck> decks = [];
  bool loading = true;
  String? errorMessage;
  final Map<String, String> userNames = {}; 

  @override
  void initState() {
    super.initState();
    fetchDecks();
  }

  Future<void> fetchDecks() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final decksReceived = await api.getPublicDecks();

      final uniqueUserIds = decksReceived.map((d) => d.userId).toSet();
      for (final id in uniqueUserIds) {
        if (id.isEmpty) continue;
        if (!userNames.containsKey(id)) {
          try {
            final userJson = await api.getUserById(id);
            userNames[id] = userJson['username'] ?? 'Unknown';
          } catch (e) {
            userNames[id] = 'Unknown';
          }
        }
      }

      setState(() {
        decks = decksReceived.map((d) => Deck.fromJson(d.toJson())).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }


  void openDeck(Deck deck) async {
    setState(() => loading = true);
    try {
      final response = await api.getDeckById(deck.id);

      // Some APIs return a Map<String, dynamic>, others a Deck object.
      // If it's a Map, convert it to Deck.fromJson.
      final loadedDeck = response is Deck
          ? response
          : Deck.fromJson(response as Map<String, dynamic>);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeckBuilderPage(existingDeck: loadedDeck),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching deck: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void createNewDeck() {
    final userId = Provider.of<UserProvider>(context, listen: false).currentUser?.id ?? '';
    final newDeck = Deck(
      id: '',
      userId: userId,
      deckname: '',
      public: false,
      cards: [],
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeckBuilderPage(existingDeck: newDeck)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<UserProvider>().isLoggedIn;

    return Scaffold(
      appBar: const TopNavAppBar(title: "Home"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : decks.isEmpty
                  ? const Center(child: Text('No public decks found'))
                  : RefreshIndicator(
                      onRefresh: fetchDecks,
                      child: ListView.builder(
                        itemCount: decks.length,
                        itemBuilder: (context, index) {
                          final deck = decks[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text(deck.deckname.isEmpty ? 'Unnamed Deck' : deck.deckname),
                              subtitle: Text('by ${userNames[deck.userId] ?? "Loading..."}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                              onTap: () => openDeck(deck),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
