class Card {
  late String id;
  late String name;
  late String set;
  late String cardType;
  late String color;
  late int apCost;
  late int bp;
  late String effect;
  late String trigger;
  late String affinity;
  late String rarity;
  late String image;

  Card(
    {
      required this.id,
      required this.name,
      required this.set,
      required this.cardType,
      required this.color,
      required this.apCost,
      required this.bp,
      required this.effect,
      required this.trigger,
      required this.affinity,
      required this.rarity,
      required this.image
    }
  );

  Card.fromJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'] as String? ?? '';
    name = parsedJson['name'] as String? ?? '';
    set = parsedJson['set'] as String? ?? '';
    cardType = parsedJson['type'] as String? ?? '';
    color = parsedJson['needEnergy']?['value'] as String? ?? '';
    apCost = int.tryParse(parsedJson['ap']?.toString() ?? '') ?? 0;
    bp = int.tryParse(parsedJson['bp']?.toString() ?? '') ?? 0;
    effect = parsedJson['effect'] as String? ?? '';
    trigger = parsedJson['trigger'] as String? ?? '';
    affinity = parsedJson['affinity'] as String? ?? '';
    rarity = parsedJson['rarity'] as String? ?? '';
    image = parsedJson['images']?['small'] as String? ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'set': set,
      'type': cardType,
      'needEnergy': {'value': color},
      'ap': apCost,
      'bp': bp,
      'effect': effect,
      'trigger': trigger,
      'affinity': affinity,
      'rarity': rarity,
      'images': {'small': image},
    };
  }
}