import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioDownloader {
  final Dio _dio = Dio();
  
  DioDownloader() {
    _dio.options.headers = {
      'x-api-key': 'pxrAEVHPV2S0yczPyv9bE9n8JryVwJAw',
      'content-type': 'application/json; charset=utf-8',
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
  }

  Future<Map<String, dynamic>?> getVideoInfo(String url) async {
    try {
      final response = await _dio.post(
        'https://tera.backend.live/allinone',
        data: {'url': url},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        String? videoUrl;
        String? thumbnail;
        String? title;

        if (data is Map) {
          // Prioritize 'video' key as per the working Python script
          if (data['video'] != null && data['video'] is List && (data['video'] as List).isNotEmpty) {
            final videoEntry = (data['video'] as List)[0];
            if (videoEntry is Map) {
              videoUrl = videoEntry['video'] ?? videoEntry['url'];
              thumbnail = videoEntry['thumbnail'];
              title = videoEntry['title'] ?? videoEntry['name'] ?? videoEntry['filename'];
            } else if (videoEntry is String) {
              videoUrl = videoEntry;
            }
          }

          // Fallback to other common keys if 'video' key doesn't provide the URL
          videoUrl = videoUrl ?? data['url'] ?? data['video_url'] ?? data['videoUrl'] ?? data['download_url'] ?? data['downloadUrl'];
          thumbnail = thumbnail ?? data['thumbnail'] ?? data['thumb'] ?? data['image'] ?? data['preview'];
          title = title ?? data['title'] ?? data['name'] ?? data['filename'];

          // If data has a 'data' field, check inside it
          if (data['data'] != null && data['data'] is Map) {
            final innerData = data['data'];
            videoUrl = videoUrl ?? innerData['url'] ?? innerData['video_url'] ?? innerData['videoUrl'] ?? innerData['download_url'] ?? innerData['downloadUrl'];
            thumbnail = thumbnail ?? innerData['thumbnail'] ?? innerData['thumb'] ?? innerData['image'] ?? innerData['preview'];
            title = title ?? innerData['title'] ?? innerData['name'] ?? innerData['filename'];
          }

          // If data has a 'result' field, check inside it
          if (data['result'] != null && data['result'] is Map) {
            final resultData = data['result'];
            videoUrl = videoUrl ?? resultData['url'] ?? resultData['video_url'] ?? resultData['videoUrl'] ?? resultData['download_url'] ?? resultData['downloadUrl'];
            thumbnail = thumbnail ?? resultData['thumbnail'] ?? resultData['thumb'] ?? resultData['image'] ?? resultData['preview'];
            title = title ?? resultData['title'] ?? resultData['name'] ?? resultData['filename'];
          }
        }

        if (videoUrl != null && videoUrl.isNotEmpty) {
          return {
            'videoUrl': videoUrl,
            'thumbnail': thumbnail,
            'title': title ?? 'Video',
          };
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting video info: $e');
      return null;
    }
  }

  Future<void> downloadVideo(
    String videoUrl, 
    String filename, {
    Function(double)? onProgress,
  }) async {
    try {
      // Create ParrotDownloader directory
      final directory = Directory('/storage/emulated/0/ParrotDownloader');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate timestamped filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtension(videoUrl);
      final finalFilename = '${filename}_$timestamp$extension';
      final filePath = '${directory.path}/$finalFilename';

      // Download the video
      await _dio.download(
        videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      debugPrint('Video downloaded to: $filePath');
    } catch (e) {
      debugPrint('Error downloading video: $e');
      rethrow;
    }
  }

  Future<void> downloadThumbnail(String thumbnailUrl, String filename) async {
    try {
      // Create Pictures directory path
      final directory = Directory('/storage/emulated/0/Pictures');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate timestamped filename for thumbnail
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtension(thumbnailUrl);
      final finalFilename = '${filename}_thumb_$timestamp$extension';
      final filePath = '${directory.path}/$finalFilename';

      // Download the thumbnail
      await _dio.download(thumbnailUrl, filePath);

      debugPrint('Thumbnail downloaded to: $filePath');
    } catch (e) {
      debugPrint('Error downloading thumbnail: $e');
      // Don't throw error for thumbnail download failure
    }
  }

  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      
      if (lastDot != -1 && lastDot < path.length - 1) {
        final extension = path.substring(lastDot);
        // Common video extensions
        if (['.mp4', '.avi', '.mov', '.mkv', '.webm', '.flv'].contains(extension.toLowerCase())) {
          return extension;
        }
        // Common image extensions
        if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension.toLowerCase())) {
          return extension;
        }
      }
      
      // Default to .mp4 for videos, .jpg for images
      return url.contains('thumb') || url.contains('image') ? '.jpg' : '.mp4';
    } catch (e) {
      return '.mp4';
    }
  }
}


