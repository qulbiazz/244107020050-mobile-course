import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'providers.dart';

class PagedPostsState {
  const PagedPostsState({
    this.items = const [],
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> items;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  PagedPostsState copyWith({
    List<Post>? items,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return PagedPostsState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

class PagedPostsNotifier extends Notifier<PagedPostsState> {
  bool _isRequestInFlight = false;

  @override
  PagedPostsState build() {
    Future.microtask(loadFirstPage);
    return const PagedPostsState(isLoading: true);
  }

  Future<void> loadFirstPage() async {
    if (_isRequestInFlight) return;
    _isRequestInFlight = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await ref.read(postRepositoryProvider).fetchPostsPage(
        page: 1,
        limit: 10,
      );

      state = state.copyWith(
        items: items,
        page: 1,
        isLoading: false,
        isLoadingMore: false,
        hasMore: items.length == 10,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        items: const [],
        page: 0,
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
        error: e,
      );
    } finally {
      _isRequestInFlight = false;
    }
  }

  Future<void> loadNextPage() async {
    if (_isRequestInFlight || state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    _isRequestInFlight = true;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final nextPage = state.page + 1;
      final items = await ref.read(postRepositoryProvider).fetchPostsPage(
        page: nextPage,
        limit: 10,
      );

      final merged = [...state.items, ...items];
      state = state.copyWith(
        items: merged,
        page: nextPage,
        isLoadingMore: false,
        hasMore: items.length == 10,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    } finally {
      _isRequestInFlight = false;
    }
  }
}

final pagedPostsProvider = NotifierProvider<PagedPostsNotifier, PagedPostsState>(
  PagedPostsNotifier.new,
);
