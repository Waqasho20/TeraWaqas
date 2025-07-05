import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'utils/dio_download.dart';

void main() {
  runApp(const ParrotDownloaderApp());
}

class ParrotDownloaderApp extends StatelessWidget {
  const ParrotDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parrot Downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';
  String? _videoUrl;
  String? _thumbnailUrl;
  String? _title;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.notification,
    ].request();
  }

  bool _isValidUrl(String url) {
    return url.contains('facebook.com') || 
           url.contains('fb.watch') || 
           url.contains('instagram.com') ||
           url.contains('instagr.am');
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  Future<void> _processUrl() async {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      _showToast('Please enter a URL');
      return;
    }

    if (!_isValidUrl(url)) {
      _showToast('Please enter a valid Facebook or Instagram URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Processing URL...';
      _downloadProgress = 0.0;
      _videoUrl = null;
      _thumbnailUrl = null;
      _title = null;
    });

    try {
      final downloader = DioDownloader();
      final result = await downloader.getVideoInfo(url);
      
      if (result != null) {
        setState(() {
          _videoUrl = result['videoUrl'];
          _thumbnailUrl = result['thumbnail'];
          _title = result['title'] ?? 'Video';
          _statusMessage = 'Video found! Ready to download.';
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to get video information';
        });
        _showToast('Failed to process URL');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showToast('Error processing URL');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadVideo() async {
    if (_videoUrl == null) {
      _showToast('No video URL available');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting download...';
      _downloadProgress = 0.0;
    });

    try {
      final downloader = DioDownloader();
      await downloader.downloadVideo(
        _videoUrl!,
        _title ?? 'video',
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
            _statusMessage = 'Downloading... ${(progress * 100).toInt()}%';
          });
        },
      );

      // Download thumbnail if available
      if (_thumbnailUrl != null) {
        await downloader.downloadThumbnail(_thumbnailUrl!, _title ?? 'thumbnail');
      }

      setState(() {
        _statusMessage = 'Download completed successfully!';
      });
      _showToast('Video downloaded successfully!');
    } catch (e) {
      setState(() {
        _statusMessage = 'Download failed: ${e.toString()}';
      });
      _showToast('Download failed');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Parrot Downloader',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // App Icon and Title
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.download,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Download Facebook & Instagram Videos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // URL Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Paste Facebook or Instagram video URL here...',
                      prefixIcon: Icon(Icons.link, color: Colors.blue),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Process URL Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _processUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading && _videoUrl == null
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 20,
                        )
                      : const Text(
                          'Process URL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                const SizedBox(height: 20),
                
                // Video Preview and Download Section
                if (_videoUrl != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title ?? 'Video',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        if (_thumbnailUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _thumbnailUrl!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.video_library,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _downloadVideo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading && _downloadProgress > 0
                                ? Text(
                                    'Downloading... ${(_downloadProgress * 100).toInt()}%',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                : const Text(
                                    'Download Video',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Progress Bar
                if (_downloadProgress > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${(_downloadProgress * 100).toInt()}% completed',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Status Message
                if (_statusMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

