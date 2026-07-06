import 'package:campus_connect/providers/search_providers.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../widgets/custom_header.dart';
import '../models/notice.dart';
import '../services/api_service.dart';
import 'notice_details.dart';

class NoticesFeed extends StatefulWidget {
  const NoticesFeed({super.key});

  @override
  State<NoticesFeed> createState() => _NoticesFeedState();
}
class _NoticesFeedState extends State<NoticesFeed> {
  late Future<List<Notice>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _noticesFuture = _loadNotices();
  }

  Future<void> _handleRefresh() async {
    try {
      // Force an explicit API call for the refresh
      final freshData = await ApiService().fetchNotices();
      if (mounted) {
        setState(() {
          // Update the future with the fresh data immediately
          _noticesFuture = Future.value(freshData);
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
              onPressed: () {
                // Re-trigger the refresh indicator programmatically or just call method
                _handleRefresh();
              },
            ),
          ),
        );
      }
    }
  }

  // The Smart Fetching & Caching Logic
  Future<List<Notice>> _loadNotices({bool isRetry = false}) async {
    try {
      final data = await ApiService().fetchNotices();

      // If this was a retry and it succeeded, tell the user they are back online!
      if (isRetry && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Back Online! Showing live data.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return data;

    } catch (e) {
      // If fetching fails (offline), pull the cache
      final cachedData = await ApiService().getCachedNotices();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No Internet Connection. Showing Cached Data'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(days: 365), // Keeps it visible until they retry
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.blueAccent,
              onPressed: () {
                // Instantly show loading state and attempt to fetch again
                setState(() {
                  _noticesFuture = _loadNotices(isRetry: true);
                });
              },
            ),
          ),
        );
      }

      // If we have cached data, return it to the UI. If cache is also empty, throw.
      if (cachedData.isNotEmpty) {
        return cachedData;
      } else {
        throw Exception('No internet and no cached data.');
      }
    }
  }

  String _getTimeAgo(DateTime createdAt) {
    final Duration diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return '${diff.inSeconds < 0 ? 0 : diff.inSeconds}s ago';
  }

  // Dummy data for Skeletonizer
  final List<Notice> _dummyNotices = List.generate(
    4,
        (index) => Notice(id: 'fake_$index', title: 'Loading a very long notice title here', content: 'Loading content...', category: 'Category', authorName: 'Admin', createdAt: DateTime.now(), thumbnailUrl: null),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          const CustomHeader(title: 'Campus Connect', searchHint: 'Search notices...',searchType: SearchType.notices,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Latest Notices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Notice>>(
              future: _noticesFuture,
              builder: (context, snapshot) {
                // If offline AND cache is empty
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 50, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No Connection & No Cached Data', style: TextStyle(color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: () => setState(() { _noticesFuture = _loadNotices(isRetry: true); }),
                          child: const Text('Try Again'),
                        )
                      ],
                    ),
                  );
                }

                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final notices = isLoading ? _dummyNotices : snapshot.data!;

                return Skeletonizer(
                  enabled: isLoading,
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh, // 👈 BIND THE METHOD
                    color: const Color(0xFF1D4ED8), // Matches your app theme
                    backgroundColor: Colors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: notices.length,
                      itemBuilder: (context, index) {
                        final notice = notices[index];
                        final themeColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
                        final color = themeColors[index % themeColors.length];
                    
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => NoticeDetailsScreen(noticeId: notice.id)));
                          },
                          child: _buildNoticeCard(
                            title: notice.title,
                            category: notice.category,
                            desc: notice.content,
                            time: _getTimeAgo(notice.createdAt),
                            imageUrl: notice.thumbnailUrl ?? 'https://via.placeholder.com/150',
                            themeColor: color,
                          ),
                        );
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

  Widget _buildNoticeCard({
    required String title,
    required String category,
    required String desc,
    required String time,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: themeColor.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                // Skeletonizer handles the loading, so we don't need a placeholder here anymore!
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                width: 80,
                height: 80,
                fit: BoxFit.fill,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),maxLines: 1,overflow: TextOverflow.ellipsis,),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(color: themeColor.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              const SizedBox(height: 24),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }
}