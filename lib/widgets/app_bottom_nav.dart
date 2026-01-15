import 'dart:ui';
import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<Map<String, dynamic>> items;

  const AppBottomNav(
      {super.key,
      required this.currentIndex,
      required this.onTap,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(35),
              border:
                  Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final bool isActive = index == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.all(isActive ? 12 : 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).primaryColor.withOpacity(0.9)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: isActive ? 26 : 22,
                          color: isActive
                              ? Colors.white
                              : Theme.of(context)
                                  .iconTheme
                                  .color!
                                  .withOpacity(0.7),
                        ),
                        if (isActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(item['label'] as String,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// Default nav items used across the app. Order must match screens where used.
const List<Map<String, dynamic>> defaultNavItems = [
  {'icon': Icons.home_rounded, 'label': 'Home'},
  {'icon': Icons.menu_book_rounded, 'label': 'Books'},
  {'icon': Icons.article_rounded, 'label': 'Papers'},
  {'icon': Icons.smart_toy_rounded, 'label': 'AI'},
  {'icon': Icons.timer_rounded, 'label': 'Timer'},
  {'icon': Icons.edit_note_rounded, 'label': 'Notes'},
  {'icon': Icons.camera_alt_rounded, 'label': 'Camera'},
  {'icon': Icons.picture_as_pdf_rounded, 'label': 'PDF'},
  {'icon': Icons.person_rounded, 'label': 'Profile'},
];
