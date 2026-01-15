import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import '../models/paper_model.dart';
import 'pdf_viewer_screen.dart';
import 'profile_screen.dart';
import '../helper/global.dart';

class PaperScreen extends StatefulWidget {
  const PaperScreen({super.key});

  @override
  State<PaperScreen> createState() => _PaperScreenState();
}

class _PaperScreenState extends State<PaperScreen> {
  String selectedGrade = "All";
  String selectedYear = "All";
  String selectedTerm = "All";
  String selectedSubject = "All";
  String selectedMedium = "All";

  final TextEditingController _searchController = TextEditingController();

  final List<String> grades = [
    "All",
    "Grade 6",
    "Grade 7",
    "Grade 8",
    "Grade 9",
    "Grade 10",
    "Grade 11",
  ];
  final List<String> years = ["All", "2019", "2020", "2021", "2022", "2023"];
  final List<String> terms = ["All", "1st Term", "2nd Term", "3rd Term"];
  final List<String> subjects = [
    "All",
    "Mathematics",
    "Science",
    "History",
    "Religious",
  ];
  final List<String> mediums = ["All", "Sinhala", "Tamil", "English"];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _performDownload(PaperModel paper) async {
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
                        "Downloading Paper",
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        paper.subject,
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

    openLink(paper.downloadUrl);
    addPointsToUser(10);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("You earned 10 points!"),
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
    final filteredPapers = papers.where((paper) {
      final gradeMatch = selectedGrade == "All" || paper.grade == selectedGrade;
      final yearMatch = selectedYear == "All" || paper.year == selectedYear;
      final termMatch = selectedTerm == "All" || paper.term == selectedTerm;
      final subjectMatch =
          selectedSubject == "All" || paper.subject == selectedSubject;
      final mediumMatch =
          selectedMedium == "All" || paper.medium == selectedMedium;
      final titleMatch = searchText.isEmpty ||
          ("${paper.subject} ${paper.grade} ${paper.year}")
              .toLowerCase()
              .contains(searchText);
      return gradeMatch &&
          yearMatch &&
          termMatch &&
          subjectMatch &&
          mediumMatch &&
          titleMatch;
    }).toList();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Past Papers",
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          centerTitle: true,
          iconTheme: Theme.of(context).appBarTheme.iconTheme,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'Search papers by title...',
                    hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color),
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context)
                            .iconTheme
                            .color
                            ?.withOpacity(0.5)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildDropdown(
                      "Grade",
                      grades,
                      selectedGrade,
                      (val) => setState(() => selectedGrade = val!),
                    ),
                    const SizedBox(width: 8),
                    buildDropdown(
                      "Year",
                      years,
                      selectedYear,
                      (val) => setState(() => selectedYear = val!),
                    ),
                    const SizedBox(width: 8),
                    buildDropdown(
                      "Term",
                      terms,
                      selectedTerm,
                      (val) => setState(() => selectedTerm = val!),
                    ),
                    const SizedBox(width: 8),
                    buildDropdown(
                      "Subject",
                      subjects,
                      selectedSubject,
                      (val) => setState(() => selectedSubject = val!),
                    ),
                    const SizedBox(width: 8),
                    buildDropdown(
                      "Medium",
                      mediums,
                      selectedMedium,
                      (val) => setState(() => selectedMedium = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: filteredPapers.isEmpty
                    ? Center(
                        child: Text(
                          "No papers found",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredPapers.length,
                        itemBuilder: (context, index) {
                          final paper = filteredPapers[index];

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
                                  Icons.description,
                                  color: Theme.of(context).primaryColor,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                "${paper.subject} (${paper.grade})",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                              ),

                              subtitle: Text(
                                "${paper.term} • ${paper.year} • ${paper.medium}",
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                  fontSize: 13,
                                ),
                              ),

                              // Preview and share actions
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        togglePaperFavorite(paper);
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(paper.isFavorite
                                                ? 'Added to favourites'
                                                : 'Removed from favourites')),
                                      );
                                    },
                                    icon: Icon(
                                      paper.isFavorite
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
                                    onPressed: () => _performDownload(paper),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PdfViewerScreen(
                                      pdfUrl: paper.downloadUrl,
                                      title:
                                          "${paper.subject} (${paper.grade}) - ${paper.year}",
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
      width: 130,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          labelStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
        dropdownColor: Theme.of(context).cardColor,
        style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13),
        items: items
            .map((e) => DropdownMenuItem(
                value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
