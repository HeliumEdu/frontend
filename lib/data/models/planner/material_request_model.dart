class MaterialRequestModel {
  final String title;
  final int? status;
  final int? condition;
  final String? website;
  final String? price;
  final String? details;
  final int materialGroup;
  final List<int>? courses;

  MaterialRequestModel({
    required this.title,
    this.status,
    this.condition,
    this.website,
    this.price,
    this.details,
    required this.materialGroup,
    this.courses,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'material_group': materialGroup,
    };

    if (status != null) data['status'] = status;
    if (condition != null) data['condition'] = condition;
    if (website != null) data['website'] = website;
    if (price != null) data['price'] = price;
    if (details != null) data['details'] = details;
    if (courses != null) data['courses'] = courses;

    return data;
  }
}
