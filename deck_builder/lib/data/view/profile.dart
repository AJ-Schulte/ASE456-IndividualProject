import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/util/api.dart';
import 'package:deck_builder/data/util/user_provider.dart';
import 'package:deck_builder/data/view/deck_builder.dart';
import 'package:deck_builder/data/model/deck.dart';
import 'package:deck_builder/data/view/top_nav_appbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final APIRunner api = APIRunner();

  late TextEditingController usernameController;
  late TextEditingController emailController;

  bool loading = false;
  bool loadingDecks = true;

  List<Deck> decks = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser!;
    usernameController = TextEditingController(text: user.username);
    emailController = TextEditingController(text: user.email);

    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() => loadingDecks = true);
    final user = context.read<UserProvider>().currentUser!;
    try {
      final data = await api.getUserDecks(user.id);
      setState(() => decks = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load decks: $e")),
      );
    } finally {
      setState(() => loadingDecks = false);
    }
  }

  Future<void> _deleteDeck(Deck deck) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Deck"),
        content: Text('Are you sure you want to delete "${deck.deckname}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await api.deleteUserAndDecks(deck.id);
      setState(() => decks.removeWhere((d) => d.id == deck.id));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deck deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete deck: $e")),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final provider = context.read<UserProvider>();
      final user = provider.currentUser!;

      final updates = {
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
      };

      final updated = await api.updateUser(user.id, updates);
      provider.setUser(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }
  
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This will permanently delete your account and all decks. "
          "This action cannot be undone.\n\nAre you sure?"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete Account",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = context.read<UserProvider>().currentUser!;
      await api.deleteUserAndDecks(user.id);

      context.read<UserProvider>().logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete account: $e")),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out')),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<UserProvider>().logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user data. Please log in.')),
      );
    }

    return Scaffold(
      appBar: const TopNavAppBar(title: "Profile"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ───── USER PROFILE FORM ───────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration:
                        const InputDecoration(labelText: 'Username'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Username cannot be empty' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Email cannot be empty' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : _updateProfile,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Update Profile'),
                  ),
                ],
              ),
            ),

            const Divider(height: 40),

            // ───── USER DECKS ───────────────────────────────
            Text(
              "Your Decks",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            if (loadingDecks)
              const Center(child: CircularProgressIndicator()),

            if (!loadingDecks && decks.isEmpty)
              const Text(
                "You have no decks yet.",
                style: TextStyle(color: Colors.grey),
              ),

            if (!loadingDecks)
              ...decks.map((deck) => Card(
              child: ListTile(
                title: Text(deck.deckname),
                subtitle: Text("Public: ${deck.public}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeckBuilderPage(existingDeck: deck),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // EDIT BUTTON
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: "Edit Deck",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeckBuilderPage(existingDeck: deck),
                          ),
                        );
                      },
                    ),

                    // DELETE BUTTON
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Delete Deck",
                      onPressed: () => _deleteDeck(deck),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 20),
            const Divider(),

            // ───── LOGOUT BUTTON ───────────────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              onPressed: _logout,
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text("Delete Account"),
              onPressed: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
