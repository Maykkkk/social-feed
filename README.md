# High-Performance Flutter Social Feed

A production-ready Flutter application demonstrating advanced performance optimizations and state management for a social media feed backed by Supabase.

## 🚀 Features

- **Infinite Scrolling**: Paginated REST API loading with pull-to-refresh
- **GPU Protection**: RepaintBoundary wrapping complex UI cards with heavy shadows
- **Memory Optimization**: cacheWidth/memCacheWidth for exact RAM footprint matching UI display size
- **Hero Animations**: Smooth transitions between feed and detail views
- **Tiered Image Loading**: Thumbnail (300px) → Mobile (1080px) → Raw (4K) progressive loading
- **Optimistic UI**: Instant like updates with 500ms debounced server synchronization
- **Offline Handling**: Graceful failure with UI reversion and SnackBar error messages

## 🏗️ Architecture

### Riverpod State Management Approach

The app uses **Riverpod** for reactive state management with the following architecture:

#### Provider Structure
```dart
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final feedNotifierProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final client = ref.read(supabaseClientProvider);
  return FeedNotifier(client, supabaseUserId);
});
```

#### StateNotifier Implementation
- **FeedNotifier** extends `StateNotifier<FeedState>` for complex state logic
- **FeedState** is an immutable class with proper copyWith methods
- **Optimistic Updates**: UI updates immediately, server calls are debounced
- **Error Handling**: Failed operations revert UI state with user feedback

#### Key State Management Patterns
1. **Debounced Network Calls**: 500ms delay prevents spam-clicking issues
2. **Server State Reconciliation**: Failed calls revert optimistic changes
3. **Pagination State**: Tracks loading, refreshing, and "has more" status
4. **Error State**: Displays retry UI instead of silent failures

### Performance Optimizations

#### RepaintBoundary Implementation & Verification

**Implementation:**
```dart
class PostCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(  // GPU isolation
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 28,  // Heavy shadow for GPU stress test
              spreadRadius: 1,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        // ... card content
      ),
    );
  }
}
```

**Verification Process:**
1. **DevTools Performance Tab**: Enable "Show repaint rainbow"
2. **Fast Scrolling Test**: Scroll rapidly through the feed
3. **GPU Rasterization Check**: Cards should show minimal/no rainbow flashing
4. **Frame Drops**: Monitor for smooth 60fps scrolling despite heavy shadows

#### memCacheWidth Implementation & Verification

**Implementation:**
```dart
// Feed thumbnails - exact UI size
Image.network(
  post.mediaThumbUrl,
  height: 260,
  cacheWidth: 780,  // Exact pixel width for UI
);

// Detail view mobile images
Image.network(
  post.mediaMobileUrl,
  cacheWidth: 1080,  // Exact pixel width for detail view
);
```

**Verification Process:**
1. **DevTools Memory Tab**: Monitor image cache usage
2. **Memory Footprint**: Confirm RAM usage matches UI dimensions, not full image sizes
3. **Scrolling Performance**: Verify smooth scrolling without memory spikes
4. **Cache Efficiency**: Check that images are reused from cache during navigation

## 🛠️ Setup Instructions

### Backend Setup (Supabase)
1. Create free Supabase project at [supabase.com](https://supabase.com)
2. Run SQL setup in Supabase SQL Editor (see `supabase_policies.sql`)
3. Create public "media" storage bucket

### Data Seeding
```bash
# Install Python dependencies
python3 -m pip install supabase Pillow

# Add images to input_images/ folder
# Update Supabase keys in seed_data.py
# Run seeding script
python3 seed_data.py
```

### Flutter Setup
```bash
# Update lib/src/services/supabase_config.dart with your keys
flutter pub get
flutter run -d chrome  # Web works best for testing
```

## 🧪 Testing Scenarios

### Performance Testing
- **Spam Clicking**: Tap like buttons 15+ times in 2 seconds
- **Rapid Scrolling**: Scroll as fast as possible (60fps maintained)
- **Memory Usage**: DevTools Memory tab shows controlled cache usage
- **Offline Mode**: Turn off Wi-Fi, tap like, expect UI revert + SnackBar

### Feature Testing
- **Infinite Scroll**: Load more posts automatically
- **Pull-to-Refresh**: Swipe down to refresh feed
- **Hero Animation**: Tap posts for smooth transitions
- **Image Loading**: Progressive quality loading (thumb → mobile → raw)

## 📊 Technical Specifications

- **Framework**: Flutter 3.11.1
- **State Management**: Riverpod 2.4.0
- **Backend**: Supabase (PostgreSQL + Storage)
- **Image Processing**: Python Pillow for tiered image generation
- **Platform Support**: iOS, Android, Web, Desktop

## 🎯 Assignment Compliance

This implementation fully satisfies the Flutter Engineering Assignment requirements:

✅ **Infinite Scrolling**: REST API with 10-item pagination
✅ **GPU Protection**: RepaintBoundary verified with DevTools
✅ **RAM Protection**: cacheWidth prevents memory bloat
✅ **Hero Animation**: Smooth transitions between screens
✅ **Tiered Loading**: Progressive image quality (thumb/mobile/raw)
✅ **Optimistic UI**: Instant feedback with debounced server calls
✅ **Offline Handling**: UI reversion with error messaging

## 📝 Submission Deliverables

1. **GitHub Repository**: https://github.com/Maykkkk/social-feed
2. **Screen Recording**: 1-2 minute video showing infinite scroll, hero transitions, and optimistic UI (success/failure scenarios)
3. **README Documentation**: This file with Riverpod and performance verification details

---

*Built with Flutter for maximum performance and user experience.*
