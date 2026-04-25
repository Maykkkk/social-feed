import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/post_model.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _hasLoadedMobile = false;
  bool _isDownloadingRaw = false;
  Uint8List? _rawImageBytes;

  @override
  void initState() {
    super.initState();
    _loadMobileImage();
  }

  Future<void> _loadMobileImage() async {
    final provider = NetworkImage(widget.post.mediaMobileUrl);
    await precacheImage(provider, context);
    if (!mounted) {
      return;
    }
    setState(() {
      _hasLoadedMobile = true;
    });
  }

  Future<void> _downloadRawImage() async {
    if (_isDownloadingRaw) {
      return;
    }

    setState(() {
      _isDownloadingRaw = true;
    });

    try {
      final response = await http.get(Uri.parse(widget.post.mediaRawUrl));
      if (response.statusCode == 200) {
        setState(() {
          _rawImageBytes = response.bodyBytes;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('High-res download failed.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('High-res download failed.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingRaw = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final imageHeight = width * 0.8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: widget.post.id,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    widget.post.mediaThumbUrl,
                    width: width,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    cacheWidth: (width * 2).round(),
                  ),
                  if (_hasLoadedMobile)
                    AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 400),
                      child: Image.network(
                        widget.post.mediaMobileUrl,
                        width: width,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        cacheWidth: 1080,
                      ),
                    )
                  else
                    const Positioned(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Likes ${widget.post.likeCount}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Icon(
                widget.post.liked ? Icons.favorite : Icons.favorite_border,
                color: widget.post.liked ? Colors.redAccent : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isDownloadingRaw ? null : _downloadRawImage,
            icon: const Icon(Icons.download),
            label: Text(_isDownloadingRaw ? 'Downloading...' : 'Download High-Res'),
          ),
          if (_rawImageBytes != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.memory(
                _rawImageBytes!,
                width: width,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
