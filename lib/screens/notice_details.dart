import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/notice.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoticeDetailsScreen extends StatefulWidget {
  final String noticeId;
  const NoticeDetailsScreen({super.key, required this.noticeId});

  @override
  State<NoticeDetailsScreen> createState() => _NoticeDetailsScreenState();
}

class _NoticeDetailsScreenState extends State<NoticeDetailsScreen> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _noticeFuture = ApiService().fetchNoticeById(widget.noticeId);
    _loadBookmarkStatus(); // Check if it's already saved when screen opens
  }

  // Load the current status from local storage
  Future<void> _loadBookmarkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // We save notice IDs in a list called 'saved_notices'
    final savedNotices = prefs.getStringList('saved_notices') ?? [];
    if (mounted) {
      setState(() {
        _isBookmarked = savedNotices.contains(widget.noticeId);
      });
    }
  }

  // Toggle the status and save it to local storage
  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotices = prefs.getStringList('saved_notices') ?? [];

    setState(() {
      if (_isBookmarked) {
        savedNotices.remove(widget.noticeId);
        _isBookmarked = false;
      } else {
        savedNotices.add(widget.noticeId);
        _isBookmarked = true;
      }
    });

    await prefs.setStringList('saved_notices', savedNotices);
  }
  late Future<Notice> _noticeFuture;
  Future<void> _launchUrl(String urlString) async {
    // 1. Clean up any accidental whitespace
    urlString = urlString.trim();

    // 2. Automatically add 'https://' if the user forgot it
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }

    final Uri url = Uri.parse(urlString);

    // 3. Launch the external browser safely
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    }
  }

  // Dummy notice for Skeletonizer
  final Notice _dummyNotice = Notice(
    id: 'dummy',
    title: 'Loading Notice Title...',
    content: 'Loading short description...',
    category: 'Category',
    authorName: 'Loading Author',
    createdAt: DateTime.now(),
    thumbnailUrl: null,
    detailedDescription: 'Loading the full details of the notice...',
    importantLinks: {'Loading': 'https://google.com'},
  );

  // Helper function to map category to color (reusing your logic)
  MaterialColor _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academics': return Colors.blue;
      case 'sports': return Colors.green;
      case 'technology': return Colors.indigo;
      case 'hostel': return Colors.orange;
      default: return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.report, color: Colors.black45), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<Notice>(
        future: _noticeFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notice', style: TextStyle(color: Colors.red.shade400)));
          }

          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final notice = isLoading ? _dummyNotice : snapshot.data!;
          final themeColor = _getCategoryColor(notice.category);

          return Skeletonizer(
            enabled: isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon/Image Container
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: themeColor.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: notice.thumbnailUrl != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: notice.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Icon(Icons.article, color: themeColor.shade400, size: 40),
                                ),
                              )
                                  : Icon(Icons.menu_book, color: themeColor.shade700, size: 40),
                            ),
                            const SizedBox(width: 16),
                            // Title & Badges
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: themeColor.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'NOTICE',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: themeColor.shade700),
                                        ),
                                      ),
                                      // REPLACED THE HARDCODED ICON WITH THIS:
                                      GestureDetector(
                                        onTap: _toggleBookmark,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          transitionBuilder: (Widget child, Animation<double> animation) {
                                            return ScaleTransition(scale: animation, child: child);
                                          },
                                          child: Icon(
                                            _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                                            key: ValueKey<bool>(_isBookmarked),
                                            color: _isBookmarked ? Colors.blue.shade700 : Colors.grey.shade400,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notice.title,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827), height: 1.2),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: themeColor.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      notice.category,
                                      style: TextStyle(color: themeColor.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          notice.content,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Info List Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.calendar_month,
                          title: 'Date',
                          value: _formatDate(notice.createdAt),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                        ),
                        _buildInfoRow(
                          icon: Icons.person,
                          title: 'Posted By',
                          value: notice.authorName,
                          //subtitle: 'IIT Kharagpur',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                        ),
                        _buildInfoRow(
                          icon: Icons.access_time_filled,
                          title: 'Posted At',
                          value: '${_formatDate(notice.createdAt)} • ${_formatTime(notice.createdAt)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Notice Details Section
                  const Text(
                    'Notice Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 12),
                  // Render the dynamic plain text from Supabase
                  Text(
                    notice.detailedDescription ?? notice.content,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  if (notice.importantLinks != null && notice.importantLinks!.isNotEmpty) ...[
                    const Text(
                      'Important Links',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 12),
                    ...notice.importantLinks!.entries.map((entry) {
                      String linkTitle = entry.key[0].toUpperCase() + entry.key.substring(1);
                      String url = entry.value.toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () => _launchUrl(url),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(linkTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                ),
                                const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  // Render the text for now

                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 20, spreadRadius: 10, offset: const Offset(0, -10))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.share),
            label: const Text('Share Notice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String value, String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.blue.shade700, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ]
            ],
          ),
        ),
      ],
    );
  }
}