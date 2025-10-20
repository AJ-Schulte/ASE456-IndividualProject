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
  int requiredEnergy;
  int generatedEnergy;
  String keywords;
  double marketPrice;

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
    this.requiredEnergy = 0,
    this.generatedEnergy = 0,
    this.keywords = '',
    this.marketPrice = 0.0,
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
      requiredEnergy: 0,
      generatedEnergy: 0,
      keywords: '',
      marketPrice: 0.0,
    );
  }

  factory Card.fromPocketBaseJson(Map<String, dynamic> json) {
    final data = json['record'] ?? json;

    String parseString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

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

    return Card(
      id: parseString(data['id']),
      cardNo: parseString(data['cardNo']),
      name: parseString(data['name']),
      seriesName: parseString(data['seriesName']),
      series: parseString(data['series']),
      category: parseString(data['categoryData']),
      color: parseString(data['color']),
      ap: parseInt(data['apData']),
      bp: parseInt(data['bpData']),
      effect: parseString(data['effectData']),
      trigger: parseString(data['triggerData']),
      attribute: parseString(data['attributeData']),
      rarity: parseString(data['rarity']),
      image: parseString(data['image']),
      requiredEnergy: parseInt(data['needEnergyData']),
      generatedEnergy: parseInt(data['generatedEnergyData']),
      keywords: parseString(data['keywords']),
      marketPrice: parseDouble(data['marketPrice']),
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
