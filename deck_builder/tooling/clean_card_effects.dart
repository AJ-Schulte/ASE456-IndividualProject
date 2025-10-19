import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

/// ---- CONFIG ----
const pocketBaseUrl = 'http://127.0.0.1:8090';
const adminEmail = 'captrockstar007@gmail.com';
const adminPassword = 'Gintamaisthebest';

Future<void> main() async {
  final pb = PocketBase(pocketBaseUrl);

  print('🔐 Logging in as superuser...');
  await pb.collection('_superusers').authWithPassword(adminEmail, adminPassword);
  print('✅ Logged in as: ${pb.authStore.token}');
  print('-----------------------------------------');

  int updated = 0;
  int skipped = 0;
  int failed = 0;

  int page = 1;
  bool done = false;

  while (!done) {
    final cards = await pb.collection('cards').getList(page: page, perPage: 100);
    if (cards.items.isEmpty) {
      done = true;
      break;
    }

    for (final card in cards.items) {
      try {
        final effect = card.data['effectData']?.toString();
        final trigger = card.data['triggerData']?.toString();

        if ((effect == null || effect.isEmpty) && (trigger == null || trigger.isEmpty)) {
          skipped++;
          continue;
        }

        final cleanedEffect = _cleanHtmlField(effect);
        final cleanedTrigger = _cleanHtmlField(trigger);

        final updateBody = <String, dynamic>{};
        if (effect != null && effect.isNotEmpty && cleanedEffect != effect) {
          updateBody['effectData'] = cleanedEffect;
        }
        if (trigger != null && trigger.isNotEmpty && cleanedTrigger != trigger) {
          updateBody['triggerData'] = cleanedTrigger;
        }

        if (updateBody.isNotEmpty) {
          await pb.collection('cards').update(card.id, body: updateBody);
          updated++;
          print('🧹 Cleaned ${card.data["name"] ?? "Unknown"}');
        } else {
          skipped++;
        }
      } catch (e) {
        failed++;
        print('❌ Error cleaning ${card.data["name"]}: $e');
      }
    }

    if (cards.items.length < 100) {
      done = true;
    } else {
      page++;
    }
  }

  print('-----------------------------------------');
  print('✅ Migration complete.');
  print('Updated: $updated, Skipped: $skipped, Failed: $failed');
}

/// Clean HTML fields into readable plain text for card effects and triggers
String _cleanHtmlField(String? rawHtml) {
  if (rawHtml == null) return '';

  String s = rawHtml
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll('|', '\n');

  final doc = parse(s);

  // Replace <img alt="..."> with readable alt text
  for (final img in doc.querySelectorAll('img')) {
    final alt = img.attributes['alt']?.trim();
    if (alt != null && alt.isNotEmpty) {
      // add colon if looks like a header (Raid, Impact, Activate)
      final prefix = RegExp(r'^(Raid|Impact|Activate)').hasMatch(alt) ? '$alt: ' : '$alt ';
      img.replaceWith(Text(prefix));
    } else {
      img.remove();
    }
  }

  // Extract text content
  String text = doc.body?.text ?? '';

  // Convert pipe '|' separators into commas or newlines
  text = text.replaceAll('|', ', ');

  // Decode HTML entities
  text = text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");

  // Normalize multiple spaces and newlines
  text = text.replaceAll(RegExp(r'\s+\n'), '\n');
  text = text.replaceAll(RegExp(r'\n{2,}'), '\n');
  text = text.replaceAll(RegExp(r'\s{2,}'), ' ');

  // Optional: remove trailing punctuation issues
  text = text.trim();

  return text;
}
