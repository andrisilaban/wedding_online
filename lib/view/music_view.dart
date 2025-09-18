import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wedding_online/models/theme_model.dart';
import 'package:wedding_online/services/music_service.dart';

class MusicPlayerWidget extends StatefulWidget {
  final WeddingTheme currentTheme;

  const MusicPlayerWidget({super.key, required this.currentTheme});

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget>
    with TickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _rotationController;
  late AnimationController _pulseController;

  String _selectedCategory = 'Romantic';
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _setupAudioPlayer();
    _initializeMusicService();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.stopped && _isLoading;
        });

        if (_isPlaying) {
          _rotationController.repeat();
          _pulseController.repeat(reverse: true);
        } else {
          _rotationController.stop();
          _pulseController.stop();
        }
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        // Update music service using proper setter
        _musicService.currentPosition = position;
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
          _isLoading = false;
        });
        // Update music service using proper setter
        _musicService.totalDuration = duration;
      }
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
        _rotationController.stop();
        _pulseController.stop();
      }
    });
  }

  Future<void> _initializeMusicService() async {
    await _musicService.loadSavedTrack();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _playTrack(MusicTrack track) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _audioPlayer.stop();

      // Try to play from assets - remove 'assets/' prefix for AssetSource
      String assetPath = track.assetPath;
      if (assetPath.startsWith('assets/')) {
        assetPath = assetPath.substring('assets/'.length);
      }

      // Try to play actual audio file
      try {
        await _audioPlayer.play(AssetSource(assetPath));
      } catch (e) {
        // If asset doesn't exist, use demo mode
        debugPrint('Asset not found, using demo mode: $e');

        // For demo, simulate the playing state
        setState(() {
          _isPlaying = true;
          _totalDuration = track.duration;
          _isLoading = false;
        });
        _rotationController.repeat();
        _pulseController.repeat(reverse: true);
        _startDemoTimer(track.duration);
      }

      await _musicService.selectTrack(track);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.music_note, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Memutar: ${track.title}')),
              ],
            ),
            backgroundColor: widget.currentTheme.primaryColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error playing track: $e');
    }
  }

  // Demo timer for when audio files are not available
  void _startDemoTimer(Duration totalDuration) {
    const updateInterval = Duration(milliseconds: 500);

    void updatePosition() {
      if (_isPlaying && mounted) {
        setState(() {
          _currentPosition = Duration(
            milliseconds:
                _currentPosition.inMilliseconds + updateInterval.inMilliseconds,
          );
        });

        // Update music service
        _musicService.currentPosition = _currentPosition;

        if (_currentPosition >= totalDuration) {
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
          });
          _rotationController.stop();
          _pulseController.stop();
        } else {
          Future.delayed(updateInterval, updatePosition);
        }
      }
    }

    updatePosition();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        // For demo mode
        setState(() {
          _isPlaying = false;
        });
        _rotationController.stop();
        _pulseController.stop();
      } else {
        if (_musicService.currentTrack != null) {
          if (_totalDuration.inMilliseconds > 0) {
            await _audioPlayer.resume();
          } else {
            await _playTrack(_musicService.currentTrack!);
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  Future<void> _seekTo(double value) async {
    if (_totalDuration.inMilliseconds > 0) {
      final position = Duration(
        milliseconds: (value * _totalDuration.inMilliseconds).round(),
      );

      try {
        await _audioPlayer.seek(position);
      } catch (e) {
        // For demo mode
        setState(() {
          _currentPosition = position;
        });
        _musicService.currentPosition = position;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _musicService,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: widget.currentTheme.primaryColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_musicService.currentTrack != null) _buildCurrentPlaying(),
                _buildCategorySelection(),
                Expanded(child: _buildTrackList()),
                if (_musicService.currentTrack != null) _buildBottomPlayer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.currentTheme.primaryColor.withOpacity(0.05),
            widget.currentTheme.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.currentTheme.primaryColor,
                  widget.currentTheme.accentColor,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.currentTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.library_music, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Music Player',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.currentTheme.textPrimary,
                    fontFamily: widget.currentTheme.fontFamily,
                  ),
                ),
                Text(
                  'Pilih musik untuk pernikahan Anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.currentTheme.textSecondary,
                    fontFamily: widget.currentTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlaying() {
    final track = _musicService.currentTrack!;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.currentTheme.primaryColor.withOpacity(0.1),
            widget.currentTheme.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.currentTheme.primaryColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.currentTheme.primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Album Art
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.currentTheme.primaryColor,
                        widget.currentTheme.accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: widget.currentTheme.primaryColor.withOpacity(
                          0.4,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.music_note, color: Colors.white, size: 30),
                      if (_isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 20),

          // Track Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.currentTheme.textPrimary,
                    fontFamily: widget.currentTheme.fontFamily,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artist,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.currentTheme.textSecondary,
                    fontFamily: widget.currentTheme.fontFamily,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? widget.currentTheme.accentColor.withOpacity(0.15)
                        : widget.currentTheme.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isPlaying
                          ? widget.currentTheme.accentColor.withOpacity(0.3)
                          : widget.currentTheme.textSecondary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying ? Icons.volume_up : Icons.music_note,
                        size: 14,
                        color: _isPlaying
                            ? widget.currentTheme.accentColor
                            : widget.currentTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPlaying
                            ? 'Playing'
                            : (_isLoading ? 'Loading...' : 'Ready'),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isPlaying
                              ? widget.currentTheme.accentColor
                              : widget.currentTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    final categories = _musicService.categories;

    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          widget.currentTheme.primaryColor,
                          widget.currentTheme.accentColor,
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: widget.currentTheme.primaryColor.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? widget.currentTheme.primaryColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : widget.currentTheme.primaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    fontFamily: widget.currentTheme.fontFamily,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackList() {
    final tracks = _musicService.getTracksByCategory(_selectedCategory);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final isSelected = _musicService.currentTrack?.id == track.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.currentTheme.primaryColor.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? widget.currentTheme.primaryColor.withOpacity(0.3)
                    : widget.currentTheme.textSecondary.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? widget.currentTheme.primaryColor.withOpacity(0.15)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            widget.currentTheme.primaryColor,
                            widget.currentTheme.accentColor,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            widget.currentTheme.textSecondary.withOpacity(0.15),
                            widget.currentTheme.textSecondary.withOpacity(0.08),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? Icons.music_note : Icons.play_arrow,
                  color: isSelected
                      ? Colors.white
                      : widget.currentTheme.textSecondary,
                  size: 26,
                ),
              ),
              title: Text(
                track.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? widget.currentTheme.primaryColor
                      : widget.currentTheme.textPrimary,
                  fontFamily: widget.currentTheme.fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.currentTheme.textSecondary,
                      fontFamily: widget.currentTheme.fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (track.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      track.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.currentTheme.textSecondary.withOpacity(
                          0.8,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    MusicService.formatDuration(track.duration),
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.currentTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    isSelected ? Icons.equalizer : Icons.play_circle_outline,
                    color: isSelected
                        ? widget.currentTheme.accentColor
                        : widget.currentTheme.primaryColor,
                    size: 20,
                  ),
                ],
              ),
              onTap: () => _playTrack(track),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPlayer() {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: widget.currentTheme.primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(
                  fontSize: 12,
                  color: widget.currentTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: widget.currentTheme.primaryColor,
                    inactiveTrackColor: widget.currentTheme.primaryColor
                        .withOpacity(0.2),
                    thumbColor: widget.currentTheme.primaryColor,
                    overlayColor: widget.currentTheme.primaryColor.withOpacity(
                      0.2,
                    ),
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: _seekTo,
                  ),
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  fontSize: 12,
                  color: widget.currentTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(Icons.shuffle, false),
              _buildControlButton(Icons.skip_previous, false),

              // Main Play/Pause Button
              GestureDetector(
                onTap: _togglePlayPause,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.currentTheme.primaryColor,
                            widget.currentTheme.accentColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: widget.currentTheme.primaryColor.withOpacity(
                              0.4,
                            ),
                            blurRadius: _isPlaying
                                ? 15 + (_pulseController.value * 5)
                                : 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isLoading
                            ? Icons.hourglass_empty
                            : (_isPlaying ? Icons.pause : Icons.play_arrow),
                        color: Colors.white,
                        size: 35,
                      ),
                    );
                  },
                ),
              ),

              _buildControlButton(Icons.skip_next, false),
              _buildControlButton(Icons.repeat, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, bool isActive) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: isActive
            ? widget.currentTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(22.5),
      ),
      child: Icon(
        icon,
        color: isActive
            ? widget.currentTheme.primaryColor
            : widget.currentTheme.textSecondary,
        size: 24,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
