import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import '../models/book_model.dart';
import 'pdf_viewer_screen.dart';
import 'profile_screen.dart';
import '../helper/global.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  String selectedGrade = "All";
  String selectedSubject = "All";
  String selectedMedium = "All";

  final List<String> grades = [
    "All",
    "Grade 6",
    "Grade 9",
    "Grade 10",
    "Grade 11",
  ];
  final List<String> subjects = [
    "All",
    "Sinhala",
    "Mathematics",
    "English",
    "Science",
    "Geography",
    "History",
    "Religious",
    "ICT",
  ];
  final List<String> mediums = ["All", "English", "Sinhala", "Tamil"];
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _performDownload(BookModel book) async {
    // Show enhanced download animation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated download icon with pulse
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1200),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (value * 0.2),
                            child: Opacity(
                              opacity: 0.6 + (value * 0.4),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.2),
                                      Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: value * 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Lottie.asset(
                                    'assets/lottie/loading.json',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.cloud_download_rounded,
                                        size: 50,
                                        color: Theme.of(context).primaryColor,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Downloading Book",
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // Progress indicator
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor:
                              Theme.of(context).dividerColor.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Preparing download...",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simulate delay for download animation
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) Navigator.of(context).pop(); // Close dialog

    openLink(book.downloadUrl);
    addPointsToUser(15);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("You earned 15 points!"),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  Future<void> openLink(String url) async {
    final Uri link = Uri.parse(url);
    if (!await launchUrl(link, mode: LaunchMode.externalApplication)) {
      throw Exception("Couldn't open the file");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchText = _searchController.text.trim().toLowerCase();
    final filteredBooks = books.where((book) {
      final gradeMatch = selectedGrade == "All" || book.grade == selectedGrade;
      final subjectMatch =
          selectedSubject == "All" || book.subject == selectedSubject;
      final mediumMatch =
          selectedMedium == "All" || book.medium == selectedMedium;
      final titleMatch = searchText.isEmpty ||
          ("${book.title} ${book.subject} ${book.grade}")
              .toLowerCase()
              .contains(searchText);
      return gradeMatch && subjectMatch && mediumMatch && titleMatch;
    }).toList();

    return SafeArea(
      child: Scaffold(
        // backgroundColor: const Color(0xff121B22),
        appBar: AppBar(
          title: Text("Books",
              style: Theme.of(context).appBarTheme.titleTextStyle),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          centerTitle: true,
          iconTheme: Theme.of(context).appBarTheme.iconTheme,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Search + layout toggle
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'Search books...',
                        hintStyle: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodySmall?.color),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context)
                              .iconTheme
                              .color
                              ?.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  buildDropdown(
                    "Grade",
                    grades,
                    selectedGrade,
                    (val) => setState(() => selectedGrade = val!),
                  ),
                  buildDropdown(
                    "Subject",
                    subjects,
                    selectedSubject,
                    (val) => setState(() => selectedSubject = val!),
                  ),
                  buildDropdown(
                    "Medium",
                    mediums,
                    selectedMedium,
                    (val) => setState(() => selectedMedium = val!),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: filteredBooks.isEmpty
                    ? Center(
                        child: Text(
                          "No books found",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 16),
                        ),
                      )
                    : _isGridView
                        ? GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              return Card(
                                color: Theme.of(context).cardColor,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PdfViewerScreen(
                                          pdfUrl: book.downloadUrl,
                                          title: book.title,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Icon(
                                            Icons.menu_book,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 48,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          book.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${book.grade} • ${book.medium}",
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  toggleBookFavorite(book);
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(book
                                                              .isFavorite
                                                          ? 'Added to favourites'
                                                          : 'Removed from favourites')),
                                                );
                                              },
                                              icon: Icon(
                                                book.isFavorite
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: const Color(0xFFFF4081),
                                                size: 20,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            PdfViewerScreen(
                                                          pdfUrl:
                                                              book.downloadUrl,
                                                          title: book.title,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: Icon(
                                                    Icons.remove_red_eye,
                                                    color: Theme.of(context)
                                                        .iconTheme
                                                        .color
                                                        ?.withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () =>
                                                      _performDownload(book),
                                                  icon: Icon(
                                                    Icons.download_rounded,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    size: 20,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              return Card(
                                color: Theme.of(context).cardColor,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.menu_book,
                                      color: Theme.of(context).primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    book.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${book.grade} - ${book.subject} (${book.medium})",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Favorite Button
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            toggleBookFavorite(book);
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(book.isFavorite
                                                    ? 'Added to favourites'
                                                    : 'Removed from favourites')),
                                          );
                                        },
                                        icon: Icon(
                                          book.isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: const Color(0xFFFF4081),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.download_rounded,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        onPressed: () => _performDownload(book),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PdfViewerScreen(
                                          pdfUrl: book.downloadUrl,
                                          title: book.title,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: 140,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          labelStyle:
              TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
        dropdownColor: Theme.of(context).cardColor,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        items: items
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
