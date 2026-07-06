import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notice.dart';
import '../models/event.dart';
import '../providers/search_providers.dart';
import 'notice_details.dart';
import 'event_details.dart';

class FullScreenSearch extends ConsumerStatefulWidget {
  final SearchType searchType;
  final String searchHint;

  const FullScreenSearch({super.key, required this.searchType, required this.searchHint});

  @override
  ConsumerState<FullScreenSearch> createState() => _FullScreenSearchState();
}

class _FullScreenSearchState extends ConsumerState<FullScreenSearch> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Dynamically route to the correct provider based on context
    final searchState = widget.searchType == SearchType.notices
        ? ref.watch(noticesSearchProvider)
        : widget.searchType == SearchType.events
        ? ref.watch(eventsSearchProvider)
        : ref.watch(bookmarksSearchProvider);

    final searchNotifier = widget.searchType == SearchType.notices
        ? ref.read(noticesSearchProvider.notifier)
        : widget.searchType == SearchType.events
        ? ref.read(eventsSearchProvider.notifier)
        : ref.read(bookmarksSearchProvider.notifier); // Added Bookmark

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Hero(
          tag: 'search_bar_${widget.searchType.name}',
          child: Material(
            type: MaterialType.transparency,
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey.shade500),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _controller.clear();
                    searchNotifier.onSearchChanged('');
                  },
                )
                    : null,
              ),
              onChanged: searchNotifier.onSearchChanged,
              onSubmitted: (val) => searchNotifier.saveSearchQuery(val),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: _buildBody(searchState, searchNotifier),
    );
  }

  // 2. Updated the parameter type to BaseSearchNotifier
  Widget _buildBody(SearchState state, BaseSearchNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.text.isEmpty) {
      return _buildRecentSearches(state.recentSearches, notifier);
    }

    if (state.results.isEmpty) {
      return Center(
        child: Text('No results found for "${_controller.text}"',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView.separated(
      itemCount: state.results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = state.results[index];
        return ListTile(
          leading: Icon(
            item is Event ? Icons.event : Icons.article,
            color: Colors.blue,
          ),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
          // 👉 UPDATE THIS: Check item type to display Venue or Category
          subtitle: Text(
            item is Event ? item.venue : item.category,
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            notifier.saveSearchQuery(_controller.text);
            if (item is Event) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: item.id)));
            } else if (item is Notice) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => NoticeDetailsScreen(noticeId: item.id)));
            }
          },
        );
      },
    );
  }

  // 3. Updated the parameter type to BaseSearchNotifier
  Widget _buildRecentSearches(List<String> history, BaseSearchNotifier notifier) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () => notifier.clearHistory(),
                child: const Text('Clear'),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final query = history[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(query, style: TextStyle(color: Colors.grey.shade700)),
                trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
                onTap: () {
                  _controller.text = query;
                  notifier.onSearchChanged(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}