import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import for opening URLs
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
        // Define a custom color scheme for a more modern look
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
  String? _rawApiResponse; // New variable to store raw API response
  bool _autoDownloadEnabled = true; // New variable for auto-download toggle

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    // Show welcome popup after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  // Welcome Dialog Function
  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.waving_hand,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.telegram,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome To Our App\nJoin For Updates Our Telegram Channel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            // OK Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            // Telegram Button
            ElevatedButton(
              onPressed: () {
                _openTelegramChannel();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.telegram, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Telegram',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to open Telegram channel
  Future<void> _openTelegramChannel() async {
    const telegramUrl = 'https://t.me/Waqas_Mood';
    try {
      final Uri url = Uri.parse(telegramUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showToast('Could not open Telegram channel');
      }
    } catch (e) {
      _showToast('Error opening Telegram channel');
    }
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
      _rawApiResponse = null; // Clear previous response
    });

    try {
      final downloader = DioDownloader();
      final result = await downloader.getVideoInfo(url);
      
      if (result != null) {
        setState(() {
          _videoUrl = result['videoUrl'];
          _thumbnailUrl = result['thumbnail'];
          _title = result['title'] ?? 'Video';
          _rawApiResponse = result['rawResponse']; // Store raw response
          _statusMessage = 'Video found! Ready to download.';
        });
        // Auto-start download if enabled
        if (_autoDownloadEnabled) {
          _downloadVideo();
        }
      } else {
        setState(() {
          _statusMessage = 'Failed to get video information';
          _rawApiResponse = 'No video information found or API response was null.'; // Indicate no info
        });
        _showToast('Failed to process URL');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _rawApiResponse = 'Error during API call: ${e.toString()}'; // Show error in raw response area
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
                
                // App Icon and Title
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
                      'Download Facebook & Instagram Videos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimary,
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
                
                // URL Input Field
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'Paste Facebook or Instagram video URL here...', 
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

                // Auto-download toggle
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
                
                // Process URL Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _processUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  child: _isLoading && _videoUrl == null
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 20,
                        )
                      : const Text('Process URL'),
                ),
                
                const SizedBox(height: 32),
                
                // Video Preview and Download Section
                if (_videoUrl != null) ...[
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
                              child: _isLoading && _downloadProgress > 0
                                  ? Text(
                                      'Downloading... ${(_downloadProgress * 100).toInt()}%',
                                    )
                                  : const Text('Download Video'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Progress Bar
                if (_downloadProgress > 0) ...[
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
                            '${(_downloadProgress * 100).toInt()}% completed',
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
                
                // Raw API Response for Debugging
                if (_rawApiResponse != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raw API Response (for debugging):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _rawApiResponse!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                
                // Status Message
                if (_statusMessage.isNotEmpty)
                  Card(
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

