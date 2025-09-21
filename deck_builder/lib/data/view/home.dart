import 'package:flutter/material.dart';
import 'package:deck_builder/data/util/api.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final APIRunner apiRunner = APIRunner();
  List<Map<String, dynamic>> decks = [];
  bool loading = true;
  String? errorMessage;

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
      final decksReceived = await apiRunner.getPublicDecks();
      setState(() {
        decks = decksReceived;
        loading = false;
      });
      print('Public Decks Received: $decksReceived');
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
      print('Error fetching decks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            onPressed: () {Navigator.pushNamed(context, '/login');},
            icon: Icon(Icons.person),
           ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : decks.isEmpty
                  ? Center(child: Text('No public decks found'))
                  : ListView.builder(
                      itemCount: decks.length,
                      itemBuilder: (context, index) {
                        final deck = decks[index];
                        final deckName = deck['deckname'] ?? 'Unnamed Deck';
                        final username = deck['username'] ?? 'Unknown User';

                        return Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(deckName),
                            subtitle: Text('by $username'),
                          ),
                        );
                      },
                    ),
    );
  }
}
