import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:deck_builder/data/model/card.dart';

/// 🔧 CONFIG
const String exburstUrl =
    'https://exburst.dev/uaen/external/fetch_data.php?gameid=uaen&series=kj8,yyh,bcv,aot,blc,cgh,fma,kmy,htr,jjk,rnk,opm,sao&seriesColumn=series';

const String pocketBaseUrl = 'http://127.0.0.1:8090';
const String superuserEmail = 'captrockstar007@gmail.com';
const String superuserPassword = 'Gintamaisthebest';

Future<void> main() async {
    print('🔐 Logging into PocketBase as superuser...');

    final pb = PocketBase(pocketBaseUrl);

    try {
      await pb.collection('_superusers').authWithPassword(
        superuserEmail,
        superuserPassword,
      );
    } catch (e) {
      print('❌ Login failed: $e');
      return;
    }

    if (!pb.authStore.isValid) {
      print('❌ Failed to authenticate superuser.');
      return;
    }

    print('✅ Logged in successfully. Token: ${pb.authStore.token}');

  print('🔄 Fetching cards from ExBurst API...');
  final response = await http.get(Uri.parse(exburstUrl));

  if (response.statusCode != 200) {
    print('❌ Failed to fetch from ExBurst (${response.statusCode})');
    return;
  }

  final List<dynamic> jsonCards = jsonDecode(response.body);
  print('✅ Received ${jsonCards.length} cards from ExBurst.');

  for (final data in jsonCards) {
    final card = parseExburstCard(data);
    await upsertCard(pb, card);
  }

  print('🎉 Sync complete!');
}

/// Converts a JSON record from ExBurst into your Card model
Card parseExburstCard(Map<String, dynamic> json) {
  int parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String parseString(dynamic value) => value?.toString() ?? '';

  return Card(
    id: '',
    cardNo: parseString(json['cardNo']),
    name: parseString(json['name']),
    seriesName: parseString(json['seriesName']),
    series: parseString(json['series']),
    category: parseString(json['categoryData']),
    color: parseString(json['color']),
    ap: parseInt(json['apData']),
    bp: parseInt(json['bpData']),
    effect: parseString(json['effectData']),
    trigger: parseString(json['triggerData']),
    attribute: parseString(json['attributeData']),
    rarity: parseString(json['rarity']),
    image: parseString(json['image']),
    requiredEnergy: parseInt(json['needEnergyData']),
    generatedEnergy: parseInt(json['generatedEnergyData']),
    keywords: parseString(json['keywords']),
    marketPrice: parseDouble(json['marketPrice']),
    abbreviation: parseString(json['abbreviation']),
  );
}

/// Adds or updates a card in PocketBase.
Future<void> upsertCard(PocketBase pb, Card card) async {
  try {
    // Find if the card already exists
    final result = await pb.collection('cards').getList(
          filter: 'cardNo="${card.cardNo}"',
          perPage: 1,
        );

    if (result.items.isNotEmpty) {
      final existingId = result.items.first.id;
      await pb.collection('cards').update(existingId, body: card.toJson());
      print('🟢 Updated: ${card.cardNo} (${card.name})');
    } else {
      await pb.collection('cards').create(body: card.toJson());
      print('🆕 Created: ${card.cardNo} (${card.name})');
    }
  } catch (e) {
    print('❌ Error saving card ${card.cardNo}: $e');
  }
}
