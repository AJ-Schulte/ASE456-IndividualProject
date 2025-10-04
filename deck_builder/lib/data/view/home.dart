import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/util/api.dart';
import 'package:deck_builder/data/util/user_provider.dart';

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
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isLoggedIn = userProvider.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Create New Deck',
            onPressed: () {
              Navigator.pushNamed(context, '/deckBuilder');
            },
          ),

          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              if (isLoggedIn) {
                Navigator.pushNamed(context, '/profile');
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
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
                        final deckOwner = deck['username'] ?? 'Unknown User';

                        return Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(deckName),
                            subtitle: Text('by $deckOwner'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/deckBuilder',
                                arguments: deckName,
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
