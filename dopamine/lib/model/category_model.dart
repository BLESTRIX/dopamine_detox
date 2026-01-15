class CategoryModel {
  final String id;
  final String name;
  final bool isCustom; // True if created by user, False if default

  CategoryModel({required this.id, required this.name, this.isCustom = false});
}
