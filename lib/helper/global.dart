import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book_model.dart';
import '../models/paper_model.dart';

const appName = "Vora";
late Size mq;

void initFavorites() {
  final box = Hive.box('favoritesBox');
  final favoriteIds = box.keys.cast<String>().toSet();

  for (var book in books) {
    if (favoriteIds.contains(book.id)) {
      book.isFavorite = true;
    }
  }

  for (var paper in papers) {
    if (favoriteIds.contains(paper.id)) {
      paper.isFavorite = true;
    }
  }
}

void toggleBookFavorite(BookModel book) {
  book.isFavorite = !book.isFavorite;
  final box = Hive.box('favoritesBox');
  if (book.isFavorite) {
    box.put(book.id, true);
  } else {
    box.delete(book.id);
  }
}

void togglePaperFavorite(PaperModel paper) {
  paper.isFavorite = !paper.isFavorite;
  final box = Hive.box('favoritesBox');
  if (paper.isFavorite) {
    box.put(paper.id, true);
  } else {
    box.delete(paper.id);
  }
}

final List<BookModel> books = [
  BookModel(
    title: "Sinhala Book",
    grade: "Grade 6",
    subject: "Sinhala",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1ux6eckXviAZd_cgjRgNG6Kn37iey18Aj&export=download",
  ),
  BookModel(
    title: "Mathematics Book",
    grade: "Grade 6",
    subject: "Mathematics",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1isPDvFED7E3MYVK40HjsJEaJSpduyWK9&export=download",
  ),
  BookModel(
    title: "ICT Book",
    grade: "Grade 6",
    subject: "ICT",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1SJPb-0ILIdY-KxpC9ySt4sdxOgcO5srP&export=download",
  ),
  BookModel(
    title: "Buddhism Book",
    grade: "Grade 6",
    subject: "Religious",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1z7XPRcKxiuF-RWE2ToHdUGJUrXxjfiOk&export=download",
  ),
  BookModel(
    title: "History Book",
    grade: "Grade 6",
    subject: "History",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1jA4t_wO9kE5tQz1lX2mX3nB4v5c6d7e8&export=download",
  ),
  BookModel(
    title: "Science Book",
    grade: "Grade 6",
    subject: "Science",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1kL2m_nO8pE4tQz1lX2mX3nB4v5c6d7e8&export=download",
  ),
  BookModel(
    title: "English Book",
    grade: "Grade 6",
    subject: "English",
    medium: "English",
    downloadUrl:
    "https://drive.google.com/uc?id=1mN3o_pO7qE3tQz1lX2mX3nB4v5c6d7e8&export=download",
  ),
  BookModel(
    title: "Geography Book",
    grade: "Grade 6",
    subject: "Geography",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1nO4p_qO6rE2tQz1lX2mX3nB4v5c6d7e8&export=download",
  ),
  BookModel(
    title: "Civics Book",
    grade: "Grade 6",
    subject: "Civics",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1oP5q_rO5sE1tQz1lX2mX3nB4v5c6d7e8&export=download",
  ),
  BookModel(
    title: "Health Book",
    grade: "Grade 6",
    subject: "Health",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1pQ6r_sO4tE0tQz1lX2mX3nB4v5c6d7e8&export=download",
  ),
];

final List<PaperModel> papers = [
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "1st Term",
    year: "2018",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1z7XPRcKxiuF-RWE2ToHdUGJUrXxjfiOk&export=download",
  ),
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "1st Term",
    year: "2019",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1F6uK8gpKVy4fKLIShH14E5cghSwsPr6o&export=download",
  ),
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "1st Term",
    year: "2018",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1s-VzYWDgLOvXNUbtq6bKfifBMneP-sh0&export=download",
  ),
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "1st Term",
    year: "2023",
    medium: "English",
    downloadUrl:
    "https://drive.google.com/uc?id=1fiwhwSzJSrGjUz9wT4kgoWb0PvdIHBiC&export=download",
  ),
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "1st Term",
    year: "2019",
    medium: "English",
    downloadUrl:
    "https://drive.google.com/uc?id=1rx5NMsngKiY8UEl9cSDWP2ppJbccaAAX&export=download",
  ),
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "2nd Term",
    year: "2019",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1UqiWWm6QBFfW4YPz5wIjTLwpoLhB-Ws2&export=download",
  ),
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "2nd Term",
    year: "2019",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1MDr_-P0yiLy6WizdinttZClm5o6vlt2m&export=download",
  ),
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "2nd Term",
    year: "2018",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1wofC1Dqh4KYXuUHtpM8IeYLKIbNJS80h&export=download",
  ),
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "2nd Term",
    year: "2023",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1BTUWZ8CRxbD1u-2G7a-3tVphouKhNUhy&export=download",
  ),
  PaperModel(
    subject: "Mathematics",
    grade: "Grade 6",
    term: "2nd Term",
    year: "2023",
    medium: "English",
    downloadUrl:
    "https://drive.google.com/uc?id=112naxHbi6nZzLnG_dJC1CmS0jI6US7uy&export=download",
  ),
  PaperModel(
    subject: "Science",
    grade: "Grade 6",
    term: "1st Term",
    year: "2018",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1aB2c_dO3eF4gH5iJ6kL7mN8oP9qR0sT&export=download",
  ),
  PaperModel(
    subject: "Science",
    grade: "Grade 6",
    term: "2nd Term",
    year: "2019",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1bC3d_eP4fG5hI6jK7lM8nP9oQ0rS1tU&export=download",
  ),
  PaperModel(
    subject: "History",
    grade: "Grade 6",
    term: "1st Term",
    year: "2018",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1cD4e_fQ5gH6iJ7kL8mN9oP0qR1sT2uV&export=download",
  ),
  PaperModel(
    subject: "History",
    grade: "Grade 6",
    term: "2nd Term",
    year: "2019",
    medium: "Sinhala",
    downloadUrl:
    "https://drive.google.com/uc?id=1dE5f_gR6hI7jK8mM9nP0qR1sT2uV3mW&export=download",
  ),
  PaperModel(
    subject: "English",
    grade: "Grade 6",
    term: "1st Term",
    year: "2018",
    medium: "English",
    downloadUrl:
    "https://drive.google.com/uc?id=1eF6g_hS7iJ8kL9nN0oP1qR2sT3uV4nW&export=download",
  ),
];
