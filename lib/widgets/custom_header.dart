import 'package:flutter/material.dart';

import '../providers/search_providers.dart';
import '../screens/full_search_screen.dart';


class CustomHeader extends StatelessWidget {
  final String title;
  final String searchHint;
  final SearchType? searchType; // 👈 Make this nullable

  const CustomHeader({
    super.key,
    required this.title,
    required this.searchHint,
    this.searchType, // 👈 No longer 'required'
  });

  @override
  Widget build(BuildContext context) {
    // The visual UI of the search bar (extracted so we can reuse it)
    Widget searchBarUI = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(searchHint, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFDBEAFE),
                child: const Text('RM', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          // 👈 conditional logic: only make it clickable/Hero if searchType is provided
          child: searchType != null
              ? GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      FullScreenSearch(searchType: searchType!, searchHint: searchHint),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            child: Hero(
              tag: 'search_bar_${searchType!.name}',
              child: Material(
                type: MaterialType.transparency,
                child: searchBarUI,
              ),
            ),
          )
              : searchBarUI, // Just show the static UI if it's the bookmarks page
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}