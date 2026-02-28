import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import '../models/app_setting.dart';
import 'supabase_service.dart';

class MediaProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService.instance;

  List<MediaItem> _mediaItems = [];
  Map<String, AppSetting> _settings = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isPipMode = false;
  String? _error;
  Timer? _autoAdvanceTimer;
  StreamSubscription? _mediaSubscription;
  StreamSubscription? _settingsSubscription;

  // Display modes: 'single', 'grid2', 'grid4'
  String _displayMode = 'single';

  // Getters
  List<MediaItem> get mediaItems => _mediaItems;
  Map<String, AppSetting> get settings => _settings;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isPipMode => _isPipMode;
  String? get error => _error;
  String get displayMode => _displayMode;
  MediaItem? get currentMedia =>
      _mediaItems.isNotEmpty ? _mediaItems[_currentIndex] : null;

  int get adRotationInterval {
    final setting = _settings['ad_rotation_interval'];
    return setting?.intValue ?? 10;
  }

  String get marqueeText {
    final setting = _settings['marquee_text'];
    return setting?.stringValue ?? 'Welcome to our Hospital';
  }

  String get cliniqTvPackage {
    final setting = _settings['cliniqtv_package'];
    return setting?.stringValue ?? 'com.cliniqtv.app';
  }

  /// Initialize the provider - fetch data and start real-time subscriptions
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch initial data
      _mediaItems = await _service.fetchActiveMedia();
      _settings = await _service.fetchSettings();

      // Start real-time subscriptions
      _startMediaSubscription();
      _startSettingsSubscription();

      // Start auto-advance timer
      _startAutoAdvance();

      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = 'Failed to load media: $e';
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Subscribe to real-time media changes
  void _startMediaSubscription() {
    _mediaSubscription?.cancel();
    _mediaSubscription = _service.mediaStream().listen(
      (items) {
        _mediaItems = items;
        // Ensure current index is valid
        if (_currentIndex >= _mediaItems.length) {
          _currentIndex = 0;
        }
        notifyListeners();
      },
      onError: (e) {
        print('Media stream error: $e');
      },
    );
  }

  /// Subscribe to real-time settings changes
  void _startSettingsSubscription() {
    _settingsSubscription?.cancel();
    _settingsSubscription = _service.settingsStream().listen(
      (settings) {
        _settings = settings;
        // Restart auto-advance with new interval
        _startAutoAdvance();
        notifyListeners();
      },
      onError: (e) {
        print('Settings stream error: $e');
      },
    );
  }

  /// Start auto-advancing through media
  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (_mediaItems.isEmpty) return;

    final current = currentMedia;
    if (current != null && current.isImage) {
      _autoAdvanceTimer = Timer(
        Duration(seconds: adRotationInterval),
        () => nextMedia(),
      );
    }
    // For videos, advancement is handled when the video completes
  }

  /// Move to next media item
  void nextMedia() {
    if (_mediaItems.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _mediaItems.length;

    // Log playback
    final current = currentMedia;
    if (current != null) {
      _service.logPlayback(current.id);
    }

    notifyListeners();
    _startAutoAdvance();
  }

  /// Move to previous media item
  void previousMedia() {
    if (_mediaItems.isEmpty) return;
    _currentIndex =
        (_currentIndex - 1 + _mediaItems.length) % _mediaItems.length;
    notifyListeners();
    _startAutoAdvance();
  }

  /// Called when a video finishes playing
  void onVideoComplete() {
    nextMedia();
  }

  /// Set PIP mode
  void setPipMode(bool isPip) {
    _isPipMode = isPip;
    notifyListeners();
  }

  /// Set display mode: 'single', 'grid2', 'grid4'
  void setDisplayMode(String mode) {
    _displayMode = mode;
    notifyListeners();
  }

  /// Get media items for grid display
  List<MediaItem> get gridMediaItems {
    if (_mediaItems.isEmpty) return [];
    final count = _displayMode == 'grid4' ? 4 : (_displayMode == 'grid2' ? 2 : 1);
    final items = <MediaItem>[];
    for (int i = 0; i < count && i < _mediaItems.length; i++) {
      items.add(_mediaItems[(_currentIndex + i) % _mediaItems.length]);
    }
    return items;
  }

  /// Refresh media from server
  Future<void> refresh() async {
    _mediaItems = await _service.fetchActiveMedia();
    _settings = await _service.fetchSettings();
    if (_currentIndex >= _mediaItems.length) {
      _currentIndex = 0;
    }
    notifyListeners();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _mediaSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
