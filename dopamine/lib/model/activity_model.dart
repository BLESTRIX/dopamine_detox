class ActivityModel {
  final String id;
  final String title;
  final String categoryId; // Links this activity to a specific category
  final DateTime date;

  ActivityModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.date,
  });
}
