import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

// Extension to add clamp method to Duration
extension DurationExtension on Duration {
  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

// Model untuk track musik
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String assetPath;
  final String category;
  final Duration duration;
  final String description;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.assetPath,
    required this.category,
    required this.duration,
    this.description = '',
  });
}

// Music Service dengan AudioPlayer integration
class MusicService extends ChangeNotifier {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal() {
    _initializeAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Daftar musik tersedia
  static const List<MusicTrack> availableTracks = [
    // Romantic
    MusicTrack(
      id: 'romantic_1',
      title: 'A Thousand Years',
      artist: 'Christina Perri',
      assetPath: 'music/romantic_1.mp3',
      category: 'Romantic',
      duration: Duration(minutes: 4, seconds: 45),
      description: 'Lagu romantis klasik untuk momen spesial',
    ),
    MusicTrack(
      id: 'romantic_2',
      title: 'Perfect',
      artist: 'Ed Sheeran',
      assetPath: 'music/romantic_2.mp3',
      category: 'Romantic',
      duration: Duration(minutes: 4, seconds: 23),
      description: 'Melodi cinta yang sempurna',
    ),
    MusicTrack(
      id: 'romantic_3',
      title: 'All of Me',
      artist: 'John Legend',
      assetPath: 'music/romantic_3.mp3',
      category: 'Romantic',
      duration: Duration(minutes: 4, seconds: 29),
      description: 'Lagu cinta yang menyentuh hati',
    ),

    // ===== Indonesian =====
    MusicTrack(
      id: 'indonesian_1',
      title: 'Sempurna',
      artist: 'Andra & The Backbone',
      assetPath: 'music/indonesian_1.mp3',
      category: 'Indonesian',
      duration: Duration(minutes: 4, seconds: 12),
      description: 'Lagu cinta Indonesia yang populer',
    ),
    MusicTrack(
      id: 'indonesian_2',
      title: 'Cinta Ini Membunuhku',
      artist: 'D\'Masiv',
      assetPath: 'music/indonesian_2.mp3',
      category: 'Indonesian',
      duration: Duration(minutes: 4, seconds: 35),
      description: 'Balada romantis Indonesia',
    ),
    MusicTrack(
      id: 'indonesian_3',
      title: 'Hingga Ujung Waktu',
      artist: 'Seventeen',
      assetPath: 'music/indonesian_3.mp3',
      category: 'Indonesian',
      duration: Duration(minutes: 4, seconds: 18),
      description: 'Lagu cinta abadi Indonesia',
    ),

    // ===== Jawa =====
    MusicTrack(
      id: 'jawa_1',
      title: 'Kabagyan',
      artist: 'Sadewok',
      assetPath: 'music/jawa_1.mp3',
      category: 'Jawa',
      duration: Duration(minutes: 5, seconds: 15),
      description: 'Lagu Jawa bertema kebahagiaan pernikahan',
    ),
    MusicTrack(
      id: 'jawa_2',
      title: 'Kembang Wangi',
      artist: 'Happy Asmara',
      assetPath: 'music/jawa_2.mp3',
      category: 'Jawa',
      duration: Duration(minutes: 4, seconds: 45),
      description: 'Lagu Jawa modern untuk pesta pernikahan',
    ),
    MusicTrack(
      id: 'jawa_3',
      title: 'Cundamani',
      artist: 'Denny Caknan',
      assetPath: 'music/jawa_3.mp3',
      category: 'Jawa',
      duration: Duration(minutes: 5, seconds: 5),
      description: 'Lagu romantis Jawa yang populer',
    ),

    // ===== Sunda =====
    MusicTrack(
      id: 'sunda_1',
      title: 'Es Lilin',
      artist: 'Nining Meida',
      assetPath: 'music/sunda_1.mp3',
      category: 'Sunda',
      duration: Duration(minutes: 4, seconds: 55),
      description: 'Lagu Sunda klasik penuh nuansa cinta',
    ),
    MusicTrack(
      id: 'sunda_2',
      title: 'Bubuy Bulan',
      artist: 'Nining Meida',
      assetPath: 'music/sunda_2.mp3',
      category: 'Sunda',
      duration: Duration(minutes: 5, seconds: 30),
      description: 'Lagu Sunda syahdu tentang cinta',
    ),
    MusicTrack(
      id: 'sunda_3',
      title: 'Sabilulungan',
      artist: 'Mang Koko',
      assetPath: 'music/sunda_3.mp3',
      category: 'Sunda',
      duration: Duration(minutes: 5, seconds: 10),
      description: 'Lagu Sunda penuh makna kebersamaan',
    ),
    // ===== Batak =====
    MusicTrack(
      id: 'batak_1',
      title: 'Dongan Matua',
      artist: 'Traditional Batak',
      assetPath: 'music/batak_1.mp3',
      category: 'Batak',
      duration: Duration(minutes: 5, seconds: 0),
      description: 'Lagu adat Batak untuk pesta pernikahan',
    ),
    MusicTrack(
      id: 'batak_2',
      title: 'Boan Au',
      artist: 'Traditional Batak',
      assetPath: 'music/batak_2.mp3',
      category: 'Batak',
      duration: Duration(minutes: 4, seconds: 50),
      description: 'Lagu cinta Batak penuh makna',
    ),
    MusicTrack(
      id: 'batak_3',
      title: 'Holan Au Do Mangantusi Ho',
      artist: 'Traditional Batak',
      assetPath: 'music/batak_3.mp3',
      category: 'Batak',
      duration: Duration(minutes: 5, seconds: 20),
      description: 'Lagu Batak yang syahdu untuk pernikahan',
    ),
  ];

  // State management
  MusicTrack? _currentTrack;
  bool _isPlaying = false;
  bool _isMuted = false;
  double _volume = 1.0; // Increased default volume to maximum
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Getters
  MusicTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  double get volume => _volume;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  // Setters for external audio player integration
  set currentPosition(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  set totalDuration(Duration duration) {
    _totalDuration = duration;
    notifyListeners();
  }

  void _initializeAudioPlayer() {
    // Set initial volume to maximum
    _audioPlayer.setVolume(3.0);

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      _currentPosition = Duration.zero;
      notifyListeners();
    });
  }

  // Get tracks by category
  List<MusicTrack> getTracksByCategory(String category) {
    return availableTracks
        .where((track) => track.category == category)
        .toList();
  }

  // Get all categories
  List<String> get categories {
    return availableTracks.map((track) => track.category).toSet().toList();
  }

  // Load saved track
  Future<void> loadSavedTrack() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTrackId = prefs.getString('selected_music_track');
      final savedVolume =
          prefs.getDouble('music_volume') ?? 1.0; // Default to max volume
      final savedMuted = prefs.getBool('music_muted') ?? false;

      _volume = savedVolume;
      _isMuted = savedMuted;

      // Ensure volume is set properly on audio player
      await _audioPlayer.setVolume(_isMuted ? 0.0 : _volume);

      if (savedTrackId != null) {
        final track = availableTracks.firstWhere(
          (track) => track.id == savedTrackId,
          orElse: () => availableTracks.first,
        );
        await selectTrack(track, autoSave: false);
      } else {
        await selectTrack(availableTracks.first, autoSave: false);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved track: $e');
      await selectTrack(availableTracks.first, autoSave: false);
    }
  }

  // Select and save track
  Future<void> selectTrack(MusicTrack track, {bool autoSave = true}) async {
    try {
      await _audioPlayer.stop();

      _currentTrack = track;
      _totalDuration = track.duration;
      _currentPosition = Duration.zero;

      if (autoSave) {
        await _saveTrackSelection(track.id);
      }

      debugPrint('Selected track: ${track.title} by ${track.artist}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error selecting track: $e');
    }
  }

  // Save track selection
  Future<void> _saveTrackSelection(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_music_track', trackId);
    } catch (e) {
      debugPrint('Error saving track selection: $e');
    }
  }

  // Play current track
  Future<void> playCurrentTrack() async {
    if (_currentTrack == null) return;

    try {
      // Ensure volume is set before playing
      await _audioPlayer.setVolume(_isMuted ? 0.0 : _volume);
      await _audioPlayer.play(AssetSource(_currentTrack!.assetPath));
    } catch (e) {
      debugPrint('Error playing track from assets: $e');
      // Fallback for demo mode - simulate playing
      _isPlaying = true;
      _startDemoTimer();
      notifyListeners();
    }
  }

  // Play/Pause controls
  Future<void> play() async {
    try {
      if (_currentTrack == null) return;
      await _audioPlayer.setVolume(_isMuted ? 0.0 : _volume);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing track: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentPosition = Duration.zero;
    } catch (e) {
      debugPrint('Error stopping track: $e');
    }
  }

  // Volume controls - Enhanced for better volume management
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);

      // Set volume immediately on audio player
      if (!_isMuted) {
        await _audioPlayer.setVolume(_volume);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('music_volume', _volume);

      debugPrint('Volume set to: ${(_volume * 100).round()}%');
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await _audioPlayer.setVolume(_isMuted ? 0.0 : _volume);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('music_muted', _isMuted);

      debugPrint('Mute toggled: $_isMuted');
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      if (_currentTrack == null) return;

      final clampedPosition = position.clamp(Duration.zero, _totalDuration);
      await _audioPlayer.seek(clampedPosition);
      _currentPosition = clampedPosition;

      debugPrint('Seeked to: ${_currentPosition.inSeconds}s');
      notifyListeners();
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  // Demo timer for when audio files are not available
  void _startDemoTimer() {
    if (_currentTrack == null) return;

    const updateInterval = Duration(milliseconds: 500);

    void updatePosition() {
      if (_isPlaying && _currentTrack != null) {
        _currentPosition = Duration(
          milliseconds:
              _currentPosition.inMilliseconds + updateInterval.inMilliseconds,
        );

        if (_currentPosition >= _totalDuration) {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        }

        notifyListeners();

        if (_isPlaying) {
          Future.delayed(updateInterval, updatePosition);
        }
      }
    }

    updatePosition();
  }

  // Format duration for display
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  // Get progress percentage
  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
