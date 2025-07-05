# Parrot Downloader

A Flutter app that allows users to download Facebook and Instagram videos directly to their Android device.

## Features

- 📱 Clean and intuitive user interface
- 🔗 Support for Facebook and Instagram video URLs
- 📥 Direct download to device storage
- 🖼️ Thumbnail preview before download
- 📊 Download progress tracking
- 🔔 Success notifications
- 📁 Organized file storage

## Screenshots

[Add screenshots here]

## Installation

### From Releases
1. Go to the [Releases](../../releases) page
2. Download the latest APK file
3. Enable "Install from unknown sources" in your Android settings
4. Install the APK on your device

### Build from Source
1. Clone this repository
2. Make sure you have Flutter installed
3. Run `flutter pub get` to install dependencies
4. Run `flutter build apk --release` to build the APK
5. Install the APK from `build/app/outputs/flutter-apk/app-release.apk`

## Usage

1. Open the Parrot Downloader app
2. Paste a Facebook or Instagram video URL in the text field
3. Tap "Process URL" to fetch video information
4. Review the video preview and tap "Download Video"
5. Wait for the download to complete
6. Find your downloaded video in `/storage/emulated/0/ParrotDownloader/`

## Supported Platforms

- Android 5.0 (API level 21) and above

## Permissions

The app requires the following permissions:
- **Internet**: To fetch video information and download videos
- **Storage**: To save downloaded videos and thumbnails
- **Notifications**: To show download completion notifications

## Technical Details

### API Integration
- Uses the Tera Backend API for video extraction
- Endpoint: `https://tera.backend.live/allinone`
- Supports both Facebook and Instagram URLs

### File Storage
- Videos are saved to `/storage/emulated/0/ParrotDownloader/`
- Thumbnails are saved to `/storage/emulated/0/Pictures/`
- Files are timestamped to avoid conflicts

### Dependencies
- `dio`: HTTP client for API calls and downloads
- `permission_handler`: Android permissions management
- `path_provider`: File system access
- `fluttertoast`: User notifications
- `flutter_spinkit`: Loading animations
- `video_player`: Video preview capabilities

## Development

### Prerequisites
- Flutter SDK (3.19.0 or later)
- Android SDK
- Java 17

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd parrot_downloader

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Building
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This app is for educational purposes only. Please respect the terms of service of Facebook and Instagram when downloading content. Only download content that you have permission to download.

## Support

If you encounter any issues or have questions, please [open an issue](../../issues) on GitHub.

