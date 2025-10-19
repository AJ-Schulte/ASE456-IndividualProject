class Card {
  String id;
  String cardNo;
  String name;
  String seriesName;
  String series;
  String category; 
  String color;
  int ap;
  int bp;
  String effect;
  String trigger;
  String attribute;
  String rarity;
  String image;
  String requiredEnergy;
  String generatedEnergy;
  String keywords;
  String marketPrice;

  Card({
    required this.id,
    this.cardNo = '',
    this.name = '',
    this.seriesName = '',
    this.series = '',
    this.category = '',
    this.color = '',
    this.ap = 0,
    this.bp = 0,
    this.effect = '',
    this.trigger = '',
    this.attribute = '',
    this.rarity = '',
    this.image = '',
    this.requiredEnergy = '',
    this.generatedEnergy = '',
    this.keywords = '',
    this.marketPrice = '',
  });

  factory Card.empty(String name) {
    return Card(
      id: '',
      name: name,
      seriesName: '',
      series: '',
      category: '',
      color: '',
      ap: 0,
      bp: 0,
      effect: '',
      trigger: '',
      attribute: '',
      rarity: '',
      image: '',
      requiredEnergy: '',
      generatedEnergy: '',
      keywords: '',
      marketPrice: '',
    );
  }

  factory Card.fromPocketBaseJson(Map<String, dynamic> json) {
    final data = json['record'] ?? json;

    return Card(
      id: data['id'] as String? ?? '',
      cardNo: data['cardNo'] as String? ?? '',
      name: data['name'] as String? ?? '',
      seriesName: data['seriesName'] as String? ?? '',
      series: data['series'] as String? ?? '',
      category: data['categoryData'] as String? ?? '',
      color: data['color'] as String? ?? '',
      ap: (data['apData'] is num)
          ? (data['apData'] as num).toInt()
          : int.tryParse((data['apData'] ?? '0').toString()) ?? 0,
      bp: (data['bpData'] is num)
          ? (data['bpData'] as num).toInt()
          : int.tryParse((data['bpData'] ?? '0').toString()) ?? 0,
      effect: data['effectData'] as String? ?? '',
      trigger: data['triggerData'] as String? ?? '',
      attribute: data['attributeData'] as String? ?? '',
      rarity: data['rarity'] as String? ?? '',
      image: data['image'] as String? ?? '',
      requiredEnergy: data['needEnergyData'] as String? ?? '',
      generatedEnergy: data['generatedEnergyData'] as String? ?? '',
      keywords: data['keywords'] as String? ?? '',
      marketPrice: data['marketPrice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardNo': cardNo,
      'name': name,
      'seriesName': seriesName,
      'series': series,
      'categoryData': category,
      'color': color,
      'apData': ap,
      'bpData': bp,
      'effectData': effect,
      'triggerData': trigger,
      'attributeData': attribute,
      'rarity': rarity,
      'image': image,
      'needEnergyData': requiredEnergy,
      'generatedEnergyData': generatedEnergy,
      'keywords': keywords,
      'marketPrice': marketPrice,
    };
  }
}
