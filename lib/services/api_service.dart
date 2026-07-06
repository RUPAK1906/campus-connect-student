import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notice.dart';
import '../models/event.dart';

class ApiService {
  static const String baseUrl = 'https://campus-connect-api-z6og.onrender.com';

  // Add these methods inside ApiService class

  Future<List<Notice>> searchNotices(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await http.get(Uri.parse('$baseUrl/search/notices?q=$query'));
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Notice.fromJson(data)).toList();
      } else {
        throw Exception('Failed to search notices');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Event>> searchEvents(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await http.get(Uri.parse('$baseUrl/search/events?q=$query'));
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Event.fromJson(data)).toList();
      } else {
        throw Exception('Failed to search events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  // 👉 ADD THIS inside your ApiService class
  Future<List<dynamic>> searchBookmarks(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNoticeIds = prefs.getStringList('saved_notices') ?? [];
      final savedEventIds = prefs.getStringList('saved_events') ?? [];

      // Fetch all saved items
      final noticeFutures = savedNoticeIds.map((id) => fetchNoticeById(id));
      final eventFutures = savedEventIds.map((id) => fetchEventById(id));

      final notices = await Future.wait(noticeFutures);
      final events = await Future.wait(eventFutures);

      // Combine both lists
      List<dynamic> combinedList = [...notices, ...events];

      // Filter locally (case-insensitive)
      final lowercaseQuery = query.toLowerCase();
      return combinedList.where((item) {
        return item.title.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search bookmarks: $e');
    }
  }

  // --- NOTICES ---
  Future<List<Notice>> fetchNotices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notices'));

      if (response.statusCode == 200) {
        // OVERWRITE CACHE ON SUCCESS
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_notices', response.body);

        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Notice.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load notices from API');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Retrieve notices from cache
  Future<List<Notice>> getCachedNotices() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_notices');
    if (cachedData != null) {
      List jsonResponse = json.decode(cachedData);
      return jsonResponse.map((data) => Notice.fromJson(data)).toList();
    }
    return [];
  }

  Future<Notice> fetchNoticeById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notices/$id'));
      if (response.statusCode == 200) {
        return Notice.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load notice details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // --- EVENTS ---
  Future<List<Event>> fetchEvents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events'));

      if (response.statusCode == 200) {
        // OVERWRITE CACHE ON SUCCESS
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_events', response.body);

        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Event.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load events from API');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Retrieve events from cache
  Future<List<Event>> getCachedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_events');
    if (cachedData != null) {
      List jsonResponse = json.decode(cachedData);
      return jsonResponse.map((data) => Event.fromJson(data)).toList();
    }
    return [];
  }

  Future<Event> fetchEventById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/$id'));
      if (response.statusCode == 200) {
        return Event.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load event details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}