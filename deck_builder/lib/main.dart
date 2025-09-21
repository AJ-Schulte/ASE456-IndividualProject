import 'package:flutter/material.dart';
import 'package:deck_builder/data/view/home.dart';
import 'package:deck_builder/data/view/login.dart';
import 'package:deck_builder/data/view/deck_builder.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deck Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: HomePage(),

      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(), 
        '/deckBuilder': (context) => DeckBuilderPage(),
      },
    );

    
  }
}
