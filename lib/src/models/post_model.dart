class Post {
  final String id;
  final DateTime createdAt;
  final String mediaThumbUrl;
  final String mediaMobileUrl;
  final String mediaRawUrl;
  final int likeCount;
  final bool liked;

  const Post({
    required this.id,
    required this.createdAt,
    required this.mediaThumbUrl,
    required this.mediaMobileUrl,
    required this.mediaRawUrl,
    required this.likeCount,
    required this.liked,
  });

  Post copyWith({
    String? id,
    DateTime? createdAt,
    String? mediaThumbUrl,
    String? mediaMobileUrl,
    String? mediaRawUrl,
    int? likeCount,
    bool? liked,
  }) {
    return Post(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      mediaThumbUrl: mediaThumbUrl ?? this.mediaThumbUrl,
      mediaMobileUrl: mediaMobileUrl ?? this.mediaMobileUrl,
      mediaRawUrl: mediaRawUrl ?? this.mediaRawUrl,
      likeCount: likeCount ?? this.likeCount,
      liked: liked ?? this.liked,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json, String userId) {
    final likes = (json['user_likes'] as List<dynamic>?) ?? <dynamic>[];
    final liked = likes.any((dynamic item) => item['user_id'] == userId);

    return Post(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      mediaThumbUrl: json['media_thumb_url'] as String,
      mediaMobileUrl: json['media_mobile_url'] as String,
      mediaRawUrl: json['media_raw_url'] as String,
      likeCount: (json['like_count'] as int?) ?? 0,
      liked: liked,
    );
  }
}
