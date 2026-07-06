import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../providers/search_providers.dart';
import '../widgets/custom_header.dart';
import '../models/notice.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'notice_details.dart';
import 'event_details.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<dynamic>> _savedItemsFuture;

  @override
  void initState() {
    super.initState();
    _savedItemsFuture = _loadSavedItems();
  }

  Future<void> _handleRefresh() async {
    try {
      // Re-run the existing logic which fetches latest data for saved IDs
      final freshData = await _loadSavedItems();
      if (mounted) {
        setState(() {
          _savedItemsFuture = Future.value(freshData);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refetch... showing old cache data'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.blueAccent,
              onPressed: _handleRefresh,
            ),
          ),
        );
      }
    }
  }

  Future<List<dynamic>> _loadSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNoticeIds = prefs.getStringList('saved_notices') ?? [];
    final savedEventIds = prefs.getStringList('saved_events') ?? [];

    final noticeFutures = savedNoticeIds.map((id) => ApiService().fetchNoticeById(id));
    final eventFutures = savedEventIds.map((id) => ApiService().fetchEventById(id));

    final notices = await Future.wait(noticeFutures);
    final events = await Future.wait(eventFutures);

    List<dynamic> combinedList = [];
    combinedList.addAll(notices);
    combinedList.addAll(events);

    return combinedList;
  }

  // Updated logic with Undo SnackBar
  Future<void> _removeBookmark(String type, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == 'EVENT' ? 'saved_events' : 'saved_notices';
    final savedList = prefs.getStringList(key) ?? [];

    // Remember the index so we can put it back in the exact same spot if they hit undo
    final removedIndex = savedList.indexOf(id);
    if (removedIndex == -1) return;

    // Remove it and update storage
    savedList.removeAt(removedIndex);
    await prefs.setStringList(key, savedList);

    // Refresh the screen immediately
    setState(() {
      _savedItemsFuture = _loadSavedItems();
    });

    // Show the SnackBar with Undo action
    if (mounted) {
      // Clear any existing snackbars so they don't pile up
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item removed from bookmarks'),
          behavior: SnackBarBehavior.floating, // Makes it a nice floating rectangle
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.blueAccent,
            onPressed: () async {
              // UNDO LOGIC: Put it back in the list and save
              final restoreList = prefs.getStringList(key) ?? [];
              // Safely insert it back at its original position
              if (removedIndex <= restoreList.length) {
                restoreList.insert(removedIndex, id);
              } else {
                restoreList.add(id);
              }
              await prefs.setStringList(key, restoreList);

              // Refresh the screen again to show the restored item
              if (mounted) {
                setState(() {
                  _savedItemsFuture = _loadSavedItems();
                });
              }
            },
          ),
        ),
      );
    }
  }

  MaterialColor _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academics': return Colors.blue;
      case 'sports': return Colors.green;
      case 'technology': return Colors.indigo;
      case 'hostel': return Colors.orange;
      default: return Colors.blue;
    }
  }

  String _formatNoticeDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatEventDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    int hour = date.hour;
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;
    String min = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$min $period';
  }

  final List<dynamic> _dummyData = [
    Event(id: 'dummy1', title: 'Loading Event...', description: 'Loading...', category: 'technology', venue: 'Loading...', startTime: DateTime.now(), endTime: DateTime.now(), organizerName: 'Loading', thumbnailUrl: null),
    Notice(id: 'dummy2', title: 'Loading Notice...', content: 'Loading...', category: 'academics', authorName: 'Loading', createdAt: DateTime.now(), thumbnailUrl: null),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          const // Find this line inside the build method in bookmarks.dart
     CustomHeader(
      title: 'Saved Items',
        searchHint: 'Search saved items...',
        searchType: SearchType.bookmarks, // 👉 ADD THIS LINE
      ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _savedItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading saved items', style: TextStyle(color: Colors.red.shade400)));
                }

                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final items = isLoading ? _dummyData : snapshot.data!;

                if (!isLoading && items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No saved items yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return Skeletonizer(
                  enabled: isLoading,
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: const Color(0xFF1D4ED8),
                    backgroundColor: Colors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        if (item is Event) {
                          return GestureDetector(
                            // The 'await' here pauses execution until the back button is pressed!
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EventDetailsScreen(eventId: item.id))
                              );
                              // This runs exactly when they return to this screen
                              if (mounted) {
                                setState(() { _savedItemsFuture = _loadSavedItems(); });
                              }
                            },
                            child: _buildSavedCard(
                              id: item.id,
                              type: 'EVENT',
                              title: item.title,
                              subtitle: item.venue,
                              date: _formatEventDate(item.startTime),
                              desc: item.description ?? '',
                              imageUrl: item.thumbnailUrl ?? 'https://via.placeholder.com/150',
                              themeColor: _getCategoryColor(item.category),
                            ),
                          );
                        } else if (item is Notice) {
                          return GestureDetector(
                            // The 'await' here pauses execution until the back button is pressed!
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => NoticeDetailsScreen(noticeId: item.id))
                              );
                              // This runs exactly when they return to this screen
                              if (mounted) {
                                setState(() { _savedItemsFuture = _loadSavedItems(); });
                              }
                            },
                            child: _buildSavedCard(
                              id: item.id,
                              type: 'NOTICE',
                              title: item.title,
                              subtitle: item.category,
                              date: _formatNoticeDate(item.createdAt),
                              desc: item.content,
                              imageUrl: item.thumbnailUrl ?? 'https://via.placeholder.com/150',
                              themeColor: _getCategoryColor(item.category),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCard({
    required String id,
    required String type,
    required String title,
    required String subtitle,
    required String date,
    required String desc,
    required String imageUrl,
    required MaterialColor themeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: themeColor.shade50, borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: type == 'EVENT' ? Colors.indigo.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.bold,
                          color: type == 'EVENT' ? Colors.indigo.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(type == 'EVENT' ? Icons.schedule : Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(child: Text(date, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(type == 'EVENT' ? Icons.location_on : Icons.sell, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(child: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _removeBookmark(type, id),
              child: Icon(Icons.bookmark, color: Colors.blue.shade700, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}