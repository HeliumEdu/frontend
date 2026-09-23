class ResourceRequestModel {
  final String title;
  final int status;
  final int condition;
  final String website;
  final String price;
  final List<int> courses;
  final int resourceGroup;

  ResourceRequestModel({
    required this.title,
    required this.status,
    required this.condition,
    required this.website,
    required this.price,
    required this.courses,
    required this.resourceGroup,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'status': status,
      'condition': condition,
      'website': website,
      'price': price,
      'courses': courses,
      'resource_group': resourceGroup,
    };

    return data;
  }
}
