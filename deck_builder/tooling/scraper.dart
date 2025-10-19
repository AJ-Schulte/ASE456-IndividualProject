// tooling/scrape_exburst_json.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

/// PocketBase config
const pocketBaseUrl = 'http://127.0.0.1:8090';
const adminEmail = 'captrockstar007@gmail.com';
const adminPassword = 'Gintamaisthebest';

/// Exburst JSON API endpoint (multi-series)
const exburstJsonUrl =
    'https://exburst.dev/uaen/external/fetch_data.php?gameid=uaen&series=rnk,kj8,yyh,aot,bcv,cgh,blc,kmy,fma,jjk,htr,opm,sao&seriesColumn=series';

Future<void> main() async {
  final pb = PocketBase(pocketBaseUrl);

  print('🔐 Logging in as superuser...');
  await pb.collection('_superusers').authWithPassword(adminEmail, adminPassword);
  print('✅ Logged in. Token: ${pb.authStore.token}\n');

  print('🌐 Fetching JSON from Exburst...');
  final data = await fetchJson(exburstJsonUrl);
  print('🧾 Retrieved ${data.length} cards.\n');

  int added = 0, skipped = 0, failed = 0;

  for (final card in data) {
    try {
      final cardName = card['name']?.toString()?.trim() ?? '';
      if (cardName.isEmpty) continue;

      final existing = await pb.collection('cards').getList(
        filter: 'cardNo="${card['cardNo']}"',
        perPage: 1,
      );

      if (existing.items.isNotEmpty) {
        skipped++;
        continue;
      }

      final formatted = {
        'cardNo': card['cardNo'],
        'name': card['name'],
        'image': card['image'],
        'seriesName': card['seriesName'],
        'series': card['series'],
        'needEnergyData': _parseNum(card['needEnergyData']),
        'color': card['color'],
        'apData': _parseNum(card['apData']),
        'categoryData': card['categoryData'],
        'bpData': _parseNum(card['bpData']),
        'attributeData': card['attributeData'],
        'generatedEnergyData': _parseNum(card['generatedEnergyData']),
        'effectData': card['effectData'],
        'triggerData': card['triggerData'],
        'rarity': card['rarity'],
        'marketPrice': card['marketPrice'],
        'tcgplayerlink': Uri.decodeComponent(card['tcgplayerlink'] ?? ''),
        'tcgplayername': Uri.decodeComponent(card['tcgplayername'] ?? ''),
        'abbreviation': card['abbreviation'],
      };

      await pb.collection('cards').create(body: formatted);
      added++;
    } catch (e) {
      print('❌ Failed on ${card['name']}: $e');
      failed++;
    }
  }

  print('\n✅ Done.');
  print('Added: $added | Skipped: $skipped | Failed: $failed');
}

/// Fetch JSON from Exburst
Future<List<dynamic>> fetchJson(String url) async {
  final resp = await http.get(Uri.parse(url));
  if (resp.statusCode != 200) {
    throw Exception('Failed to fetch: ${resp.statusCode}');
  }
  return jsonDecode(resp.body) as List<dynamic>;
}

/// Parse numeric values safely
num _parseNum(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val;
  return num.tryParse(val.toString()) ?? 0;
}
