import 'dart:convert';

class whiskeyInfo {
  String? url;
  final String name;
  final String? alcholInfo;
  final String? desc;
  final String? baseRating;
  final int price;
  whiskeyInfo({
    this.url,
    required this.name,
    this.alcholInfo,
    this.desc,
    this.baseRating,
    required this.price,
  });

  whiskeyInfo copyWith({
    String? url,
    String? name,
    String? alcholInfo,
    String? desc,
    String? baseRating,
    int? price,
  }) {
    return whiskeyInfo(
      url: url ?? this.url,
      name: name ?? this.name,
      alcholInfo: alcholInfo ?? this.alcholInfo,
      desc: desc ?? this.desc,
      baseRating: baseRating ?? this.baseRating,
      price: price ?? this.price,
    );
  }

  factory whiskeyInfo.fromMap(Map<String, dynamic> map) {
    return whiskeyInfo(
      url: map['url'] != null ? map['url'] : null,
      name: map['name'],
      alcholInfo: map['alcholInfo'],
      desc: map['desc'],
      baseRating: map['baseRating'],
      price: map['price']?.toInt(),
    );
  }

  factory whiskeyInfo.fromJson(String source) =>
      whiskeyInfo.fromMap(json.decode(source));

  @override
  String toString() {
    return 'whiskeyInfo(url: $url, name: $name, alcholInfo: $alcholInfo, desc: $desc, baseRating: $baseRating, price: $price)';
  }
}
