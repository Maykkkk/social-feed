import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as flutter_riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post_model.dart';
import '../services/supabase_config.dart';

final supabaseClientProvider = flutter_riverpod.Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final feedNotifierProvider = flutter_riverpod.StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final client = ref.read(supabaseClientProvider);
  return FeedNotifier(client, supabaseUserId);
});

const int _pageSize = 10;
const Duration _likeFlushDebounce = Duration(milliseconds: 500);

@immutable
class FeedState {
  final List<Post> posts;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  const FeedState({
    required this.posts,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasMore,
    this.errorMessage,
  });

  factory FeedState.initial() {
    return const FeedState(
      posts: [],
      isLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      hasMore: true,
      errorMessage: null,
    );
  }

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

class FeedNotifier extends flutter_riverpod.StateNotifier<FeedState> {
  final SupabaseClient _supabase;
  final String _userId;

  final Map<String, bool> _pendingToggle = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, bool> _serverLiked = {};
  final Map<String, int> _serverLikeCount = {};

  FeedNotifier(this._supabase, this._userId) : super(FeedState.initial()) {
    refresh();
  }

  Future<void> refresh() async {
    final isInitialLoad = state.posts.isEmpty;
    state = state.copyWith(
      isRefreshing: !isInitialLoad,
      isLoading: isInitialLoad,
      errorMessage: null,
      hasMore: true,
    );
    try {
      final posts = await _fetchPosts(offset: 0);
      state = state.copyWith(
        posts: posts,
        isRefreshing: false,
        isLoading: false,
        hasMore: posts.length == _pageSize,
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        isLoading: false,
        errorMessage: 'Unable to refresh feed. Please check Supabase policies and network.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading || state.isRefreshing) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    try {
      final posts = await _fetchPosts(offset: state.posts.length);
      state = state.copyWith(
        posts: [...state.posts, ...posts],
        isLoadingMore: false,
        hasMore: posts.length == _pageSize,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Unable to load more posts. Swipe down to retry.',
      );
    }
  }

  Future<List<Post>> _fetchPosts({required int offset}) async {
    final response = await _supabase
        .from('posts')
        .select('*, user_likes(user_id)')
        .order('created_at', ascending: false)
        .range(offset, offset + _pageSize - 1);

    final data = response as List<dynamic>?;
    if (data == null) {
      return [];
    }

    final posts = data
        .map((dynamic item) => Post.fromJson(item as Map<String, dynamic>, _userId))
        .toList();

    for (final post in posts) {
      _serverLiked[post.id] = post.liked;
      _serverLikeCount[post.id] = post.likeCount;
    }

    return posts;
  }

  void toggleLike(String postId) {
    final index = state.posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      return;
    }

    final current = state.posts[index];
    final updated = current.copyWith(
      liked: !current.liked,
      likeCount: current.likeCount + (current.liked ? -1 : 1),
    );

    final updatedPosts = [...state.posts];
    updatedPosts[index] = updated;
    state = state.copyWith(posts: updatedPosts, errorMessage: null);

    _pendingToggle[postId] = !(_pendingToggle[postId] ?? false);
    _debounceTimers[postId]?.cancel();
    _debounceTimers[postId] = Timer(_likeFlushDebounce, () => _flushLike(postId));
  }

  Future<void> _flushLike(String postId) async {
    _debounceTimers.remove(postId);
    final shouldToggle = _pendingToggle.remove(postId) ?? false;
    if (!shouldToggle) {
      return;
    }

    try {
      await _supabase.rpc('toggle_like', params: {
        'p_post_id': postId,
        'p_user_id': _userId,
      });

      await _refreshPost(postId);
    } catch (error) {
      _revertLike(postId, 'Like could not be saved. Check your connection.');
    }
  }

  Future<void> _refreshPost(String postId) async {
    final response = await _supabase
        .from('posts')
        .select('*, user_likes(user_id)')
        .eq('id', postId)
        .single();

    final data = response as Map<String, dynamic>;
    final updatedPost = Post.fromJson(data, _userId);
    _serverLiked[postId] = updatedPost.liked;
    _serverLikeCount[postId] = updatedPost.likeCount;

    final index = state.posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      return;
    }

    final updatedPosts = [...state.posts];
    updatedPosts[index] = updatedPost;
    state = state.copyWith(posts: updatedPosts);
  }

  void _revertLike(String postId, String message) {
    final index = state.posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      return;
    }

    final serverLiked = _serverLiked[postId] ?? state.posts[index].liked;
    final serverLikeCount = _serverLikeCount[postId] ?? state.posts[index].likeCount;
    final revertedPost = state.posts[index].copyWith(
      liked: serverLiked,
      likeCount: serverLikeCount,
    );

    final updatedPosts = [...state.posts];
    updatedPosts[index] = revertedPost;
    state = state.copyWith(posts: updatedPosts, errorMessage: message);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  @override
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
