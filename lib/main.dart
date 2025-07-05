import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/dio_download.dart'; // Yeh import zaroori hai

void main() {
  runApp(const ParrotDownloaderApp());
}

class ParrotDownloaderApp extends StatelessWidget {
  const ParrotDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parrot Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.orangeAccent,
          background: Colors.blue.shade50,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            elevation: 5,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
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
  String? _rawApiResponse;
  bool _autoDownloadEnabled = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    
    // <<< YEH SECTION HAR BAAR DIALOG DIKHATA HAI >>>
    // Jab bhi yeh screen khulegi, yeh code dialog ko screen par le aayega.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showJoinTelegramDialog(context);
    });
  }

  Future<void> _showJoinTelegramDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.send, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text('Join Our Community'),
            ],
          ),
          content: const Text('Stay updated with the latest news and features by joining our Telegram channel.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Maybe Later'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Join Channel'),
              onPressed: () async {
                final Uri url = Uri.parse('https://t.me/Waqas_Mood');
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  _showToast('Could not launch Telegram. Please check if it is installed.');
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermissions() async {
    // Android ke naye versions ke liye storage permission ki zaroorat nahi agar aap GallerySaver istemal kar rahe hain.
    // Sirf notification ki permission maangna behtar hai.
    await Permission.notification.request();
  }

  bool _isValidUrl(String url) {
    return url.contains('facebook.com') || 
           url.contains('fb.watch') || 
           url.contains('instagram.com') ||
           url.contains('instagr.am') ||
           url.contains('threads.net'); // Threads support
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

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      _urlController.text = clipboardData.text!;
      _showToast('URL pasted from clipboard');
    } else {
      _showToast('No text found in clipboard');
    }
  }

  Future<void> _processUrl() async {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      _showToast('Please enter a URL');
      return;
    }

    if (!_isValidUrl(url)) {
      _showToast('Please enter a valid Facebook, Instagram or Threads URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Processing URL...';
      _downloadProgress = 0.0;
      _videoUrl = null;
      _thumbnailUrl = null;
      _title = null;
      _rawApiResponse = null;
    });

    try {
      final downloader = DioDownloader();
      final result = await downloader.getVideoInfo(url);
      
      if (result != null) {
        setState(() {
          _videoUrl = result['videoUrl'];
          _thumbnailUrl = result['thumbnail'];
          // Title mein ghalat characters ko hata dein jo file name mein masla kar sakte hain
          _title = result['title']?.replaceAll(RegExp(r'[^\w\s.-]'),'').trim() ?? 'video';
          _rawApiResponse = result['rawResponse'];
          _statusMessage = 'Video found! Ready to download.';
        });

        if (_autoDownloadEnabled) {
          _downloadVideo();
        }
      } else {
        setState(() {
          _statusMessage = 'Failed to get video information. The URL might be private or invalid.';
          _rawApiResponse = 'No video information found or API response was null.';
        });
        _showToast('Failed to process URL');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _rawApiResponse = 'Error during API call: ${e.toString()}';
      });
      _showToast('Error processing URL');
    } finally {
      if (!_autoDownloadEnabled || _videoUrl == null) {
        setState(() {
          _isLoading = false;
        });
      }
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

      if (_thumbnailUrl != null) {
        await downloader.downloadThumbnail(_thumbnailUrl!, _title ?? 'thumbnail');
      }

      setState(() {
        _statusMessage = 'Download completed successfully! Saved to Gallery.';
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
        title: const Text('Parrot Downloader'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade300,
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.1, 0.5, 0.9],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.cloud_download,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Download FB, Insta & Threads Videos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'Paste video URL here...', 
                    prefixIcon: Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.paste, color: Theme.of(context).colorScheme.primary),
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                
                const SizedBox(height: 24),

                SwitchListTile(
                  title: const Text(
                    'Auto-start Download',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  value: _autoDownloadEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _autoDownloadEnabled = value;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.secondary,
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _processUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading && _videoUrl == null
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 20,
                        )
                      : const Text('Process URL'),
                ),
                
                const SizedBox(height: 32),
                
                if (_videoUrl != null && !_isLoading) ...[
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title ?? 'Video',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          if (_thumbnailUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _thumbnailUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 180,
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.video_library,
                                      size: 60,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _downloadVideo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Download Video'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                if (_isLoading && _downloadProgress > 0) ...[
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _statusMessage,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (_statusMessage.isNotEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.blue.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
