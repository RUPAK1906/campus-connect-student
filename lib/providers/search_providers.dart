import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// Enum to define context
enum SearchType { notices, events, bookmarks }

class SearchState {
  final bool isLoading;
  final List<dynamic> results;
  final List<String> recentSearches;

  SearchState({
    this.isLoading = false,
    this.results = const [],
    this.recentSearches = const [],
  });

  SearchState copyWith({
    bool? isLoading,
    List<dynamic>? results,
    List<String>? recentSearches,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

// 1. We create an abstract Base Notifier that contains all the logic
abstract class BaseSearchNotifier extends Notifier<SearchState> {
  SearchType get searchType; // Subclasses will define this
  Timer? _debounceTimer;

  @override
  SearchState build() {
    _loadRecentSearches();

    // Modern Riverpod cleanup
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return SearchState();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'recent_searches_${searchType.name}';
    final history = prefs.getStringList(key) ?? [];
    state = state.copyWith(recentSearches: history);
  }

  Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'recent_searches_${searchType.name}';
    List<String> history = state.recentSearches.toList();

    history.remove(query);
    history.insert(0, query);
    if (history.length > 5) history = history.sublist(0, 5);

    await prefs.setStringList(key, history);
    state = state.copyWith(recentSearches: history);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches_${searchType.name}');
    state = state.copyWith(recentSearches: []);
  }

  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        List<dynamic> results = [];
        if (searchType == SearchType.notices) {
          results = await ApiService().searchNotices(query);
        } else if (searchType == SearchType.events) {
          results = await ApiService().searchEvents(query);
        }else if (searchType == SearchType.bookmarks) {
          // 👉 ADD THIS: Route to the new bookmarks search method
          results = await ApiService().searchBookmarks(query);
        }
        state = state.copyWith(results: results, isLoading: false);
      } catch (e) {
        state = state.copyWith(results: [], isLoading: false);
      }
    });
  }
}

// 2. Concrete Notifier for Notices
class NoticesSearchNotifier extends BaseSearchNotifier {
  @override
  SearchType get searchType => SearchType.notices;
}

// 3. Concrete Notifier for Events
class EventsSearchNotifier extends BaseSearchNotifier {
  @override
  SearchType get searchType => SearchType.events;
}
// 👉 ADD THIS: Concrete Notifier for Bookmarks
class BookmarksSearchNotifier extends BaseSearchNotifier {
  @override
  SearchType get searchType => SearchType.bookmarks;
}
// 4. Clean, standard Providers without the messy .family bounds
final noticesSearchProvider = NotifierProvider<NoticesSearchNotifier, SearchState>(NoticesSearchNotifier.new);
final eventsSearchProvider = NotifierProvider<EventsSearchNotifier, SearchState>(EventsSearchNotifier.new);
// 👉 ADD THIS: Provider for Bookmarks
final bookmarksSearchProvider = NotifierProvider<BookmarksSearchNotifier, SearchState>(BookmarksSearchNotifier.new);