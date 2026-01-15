class PaperModel {
  String subject;
  String year;
  String grade;   // e.g., Grade 9
  String term;    // 1st, 2nd, 3rd term
  String downloadUrl;
  String medium; // Sinhala, Tamil, English
  bool isFavorite;

  PaperModel({
    required this.subject,
    required this.year,
    required this.grade,
    required this.term,
    required this.downloadUrl,
    required this.medium,
    this.isFavorite = false,
  });

  String get id => '${subject}_${grade}_${term}_${year}_${medium}';
}
