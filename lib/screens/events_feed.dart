import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../providers/search_providers.dart';
import '../widgets/custom_header.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'event_details.dart';

class EventsFeed extends StatefulWidget {
  const EventsFeed({super.key});

  @override
  State<EventsFeed> createState() => _EventsFeedState();
}

class _EventsFeedState extends State<EventsFeed> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
  }

  Future<void> _handleRefresh() async {
    try {
      final freshData = await ApiService().fetchEvents();
      if (mounted) {
        setState(() {
          _eventsFuture = Future.value(freshData);
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

  // The Smart Fetching & Caching Logic
  Future<List<Event>> _loadEvents({bool isRetry = false}) async {
    try {
      final data = await ApiService().fetchEvents();

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
      final cachedData = await ApiService().getCachedEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No Internet Connection. Showing Cached Data'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(days: 365),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.blueAccent,
              onPressed: () {
                setState(() {
                  _eventsFuture = _loadEvents(isRetry: true);
                });
              },
            ),
          ),
        );
      }

      if (cachedData.isNotEmpty) {
        return cachedData;
      } else {
        throw Exception('No internet and no cached data.');
      }
    }
  }

  // Dummy data for Skeletonizer
  final List<Event> _dummyEvents = List.generate(
    3,
        (index) => Event(id: 'fake_$index', title: 'Loading a very long event title...', category: 'Category', venue: 'Loading Venue Location...', startTime: DateTime.now(), endTime: DateTime.now().add(const Duration(hours: 2)), organizerName: 'Admin', thumbnailUrl: null),
  );

  String _formatEventTime(DateTime start, DateTime end) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[start.month - 1];

    String formatTime(DateTime time) {
      int hour = time.hour;
      String period = 'AM';
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      String minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    }

    return '$month ${start.day}, ${start.year} • ${formatTime(start)} – ${formatTime(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          const CustomHeader(title: 'Campus Events', searchHint: 'Search events...',searchType: SearchType.events,),
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 50, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No Connection & No Cached Data', style: TextStyle(color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: () => setState(() { _eventsFuture = _loadEvents(isRetry: true); }),
                          child: const Text('Try Again'),
                        )
                      ],
                    ),
                  );
                }

                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final events = isLoading ? _dummyEvents : snapshot.data!;

                return Skeletonizer(
                  enabled: isLoading,
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: const Color(0xFF1D4ED8),
                    backgroundColor: Colors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final themeColors = [Colors.indigo, Colors.green, Colors.orange, Colors.red];
                        final color = themeColors[index % themeColors.length];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(eventId: event.id)));
                          },
                          child: _buildEventCard(
                            title: event.title,
                            timeString: _formatEventTime(event.startTime, event.endTime),
                            venue: event.venue,
                            imageUrl: event.thumbnailUrl ?? 'https://via.placeholder.com/150',
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


  Widget _buildEventCard({
    required String title,
    required String timeString,
    required String venue,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 56, color: Colors.grey),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text Content (Title, Time, Location)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                // Time Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        timeString,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Location Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        venue,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}