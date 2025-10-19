import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/view/home.dart';
import 'package:deck_builder/data/view/login.dart';
import 'package:deck_builder/data/view/profile.dart';
import 'package:deck_builder/data/view/deck_builder.dart';
import 'package:deck_builder/data/util/user_provider.dart';
import 'package:deck_builder/data/model/deck.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        title: 'Deck Builder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
        ),
        home: HomePage(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/home':
              return MaterialPageRoute(builder: (_) => HomePage());
            case '/login':
              return MaterialPageRoute(builder: (_) => LoginPage());
            case '/profile':
              return MaterialPageRoute(builder: (_) => ProfilePage());

            case '/deckBuilder':
              final args = settings.arguments;
              if (args is Deck) {
                return MaterialPageRoute(
                  builder: (_) => DeckBuilderPage(existingDeck: args),
                );
              }
              return MaterialPageRoute(builder: (_) => DeckBuilderPage());

            default:
              return MaterialPageRoute(builder: (_) => HomePage());
          }
        },
      ),
    );
  }
}
