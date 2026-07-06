import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart'; // Added this
import '../models/event.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Future<Event> _eventFuture;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
    _eventFuture = ApiService().fetchEventById(widget.eventId);
  }

  Future<void> _loadBookmarkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEvents = prefs.getStringList('saved_events') ?? [];
    if (mounted) {
      setState(() {
        _isBookmarked = savedEvents.contains(widget.eventId);
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEvents = prefs.getStringList('saved_events') ?? [];

    setState(() {
      if (_isBookmarked) {
        savedEvents.remove(widget.eventId);
        _isBookmarked = false;
      } else {
        savedEvents.add(widget.eventId);
        _isBookmarked = true;
      }
    });

    await prefs.setStringList('saved_events', savedEvents);
  }



  final Event _dummyEvent = Event(
    id: 'dummy',
    title: 'Loading Event Title...',
    description: 'Loading short description...',
    category: 'Category',
    venue: 'Loading Venue Location',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(hours: 2)),
    organizerName: 'Loading Organizer',
    thumbnailUrl: null,
    detailedDescription: 'Loading the full details of the event...',
    importantLinks: {'Loading': 'https://google.com'},
  );

  String _formatDateTime(DateTime start, DateTime end) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String formatTime(DateTime time) {
      int hour = time.hour;
      String period = 'AM';
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
    }

    String startDateStr = '${months[start.month - 1]} ${start.day}, ${start.year}';
    String startTimeStr = formatTime(start);
    bool isSameDay = start.year == end.year && start.month == end.month && start.day == end.day;

    if (isSameDay) {
      return '$startDateStr • $startTimeStr – ${formatTime(end)}';
    } else {
      String endDateStr = '${months[end.month - 1]} ${end.day}, ${end.year}';
      return '$startDateStr, $startTimeStr  –  $endDateStr, ${formatTime(end)}';
    }
  }

  // Helper function to safely launch URLs
  // Helper function to safely launch URLs
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
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<Event>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading event', style: TextStyle(color: Colors.red.shade400)));
          }

          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final event = isLoading ? _dummyEvent : snapshot.data!;

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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: event.thumbnailUrl ?? 'https://via.placeholder.com/150',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  width: 80, height: 80, color: Colors.indigo.shade50,
                                  child: Icon(Icons.event, color: Colors.indigo.shade200, size: 40),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                          color: Colors.indigo.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'EVENT',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
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
                                    event.title,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827), height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          event.description ?? '',
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
                          icon: Icons.access_time_filled,
                          title: 'Date & Time',
                          value: _formatDateTime(event.startTime, event.endTime),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                        ),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          title: 'Venue',
                          value: event.venue,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                        ),
                        _buildInfoRow(
                          icon: Icons.groups,
                          title: 'Organized By',
                          value: event.organizerName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. About Section (Now uses detailedDescription!)
                  const Text(
                    'About This Event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.detailedDescription ?? event.description ?? '', // Fallback to short description if detailed is null
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6),
                  ),
                  const SizedBox(height: 24),

                  // 4. Important Links Section (Dynamic!)
                  if (event.importantLinks != null && event.importantLinks!.isNotEmpty) ...[
                    const Text(
                      'Important Links',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 12),
                    // Loop through the JSON keys and generate a clickable row for each
                    ...event.importantLinks!.entries.map((entry) {
                      // Capitalize the first letter (e.g., "registration" -> "Registration")
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
                  const SizedBox(height: 100), // Padding for the bottom fixed button
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
            icon: const Icon(Icons.calendar_month),
            label: const Text('Add to Calendar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
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
            ],
          ),
        ),
      ],
    );
  }
}