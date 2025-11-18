class CategoryRequestModel {
  final String title;
  final String weight;
  final String color;

  CategoryRequestModel({
    required this.title,
    required this.weight,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {'title': title, 'weight': weight, 'color': color};
  }

  factory CategoryRequestModel.fromJson(Map<String, dynamic> json) {
    return CategoryRequestModel(
      title: json['title'] ?? '',
      weight: json['weight'] ?? '0',
      color: json['color'] ?? '#cabdbf',
    );
  }
}
