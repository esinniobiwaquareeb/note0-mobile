class Folder {
  const Folder({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
  });

  final String id;
  final String name;
  final int iconCode;
  final int colorValue;

  Folder copyWith({
    String? name,
    int? iconCode,
    int? colorValue,
  }) {
    return Folder(
      id: id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue,
    };
  }

  static Folder fromJson(Map<String, Object?> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: json['iconCode'] as int,
      colorValue: json['colorValue'] as int,
    );
  }
}
