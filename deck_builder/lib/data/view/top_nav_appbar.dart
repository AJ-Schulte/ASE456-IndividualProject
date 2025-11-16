import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/util/user_provider.dart';

class TopNavAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// default buttons: home, create deck, profile/login
  final bool showDefaultActions;

  /// whether to show the create deck (+) button
  final bool showCreateDeck;

  /// extra actions injected by a page (ex: save, filter)
  final List<Widget> extraActions;

  const TopNavAppBar({
    super.key,
    required this.title,
    this.showDefaultActions = true,
    this.showCreateDeck = true,
    this.extraActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isLoggedIn = userProvider.isLoggedIn;

    return AppBar(
      title: Text(title),
      actions: [
        // Inject page-specific buttons first
        ...extraActions,

        if (showDefaultActions) ...[
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: "Home",
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
            },
          ),

          if (showCreateDeck)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "New Deck",
              onPressed: () {
                final userId = userProvider.currentUser?.id ?? "";
                final emptyDeck = {
                  "id": "",
                  "userId": userId,
                  "deckname": "",
                  "public": false,
                  "cards": []
                };
                Navigator.pushNamed(context, "/deckBuilder",
                    arguments: emptyDeck);
              },
            ),

          IconButton(
            icon: const Icon(Icons.person),
            tooltip: isLoggedIn ? "Profile" : "Login",
            onPressed: () {
              Navigator.pushNamed(context, isLoggedIn ? "/profile" : "/login");
            },
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
