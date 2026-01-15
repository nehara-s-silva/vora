class BookModel {
  String title;
  String grade;        // Grade 1-11
  String subject;      // e.g., Language(Sinhala, Tamil, English), Mathematics, Science, History, Religious(Buddhism/Catholic), BO1, BO2, BO3
  String medium;       // Sinhala, Tamil, English
  String downloadUrl;  // Google Drive or OneDrive link
  bool isFavorite;

  BookModel({
    required this.title,
    required this.grade,
    required this.subject,
    required this.medium,
    required this.downloadUrl,
    this.isFavorite = false,
  });

  String get id => '${title}_${grade}_${subject}_${medium}';
}
