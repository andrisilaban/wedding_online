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

  late AnimationController _rotationController;
  String _selectedCategory = 'Romantic';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _initializeMusicService();
  }

  Future<void> _initializeMusicService() async {
    await _musicService.loadSavedTrack();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _playTrack(MusicTrack track) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Only show notification if it's a different track
      final bool isDifferentTrack = _musicService.currentTrack?.id != track.id;

      // Stop any currently playing track first
      await _musicService.stop();

      // Select the new track
      await _musicService.selectTrack(track);

      // Play the new track
      await _musicService.playCurrentTrack();

      setState(() {
        _isLoading = false;
      });

      // Show notification only for different tracks
      if (mounted && isDifferentTrack) {
        ScaffoldMessenger.of(
          context,
        ).clearSnackBars(); // Clear any existing snackbars
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Memutar: ${track.title}'),
            backgroundColor: widget.currentTheme.primaryColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
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

  Future<void> _togglePlayPause() async {
    if (_musicService.currentTrack == null) return;

    if (_musicService.isPlaying) {
      await _musicService.pause();
    } else {
      await _musicService.play();
    }
  }

  Future<void> _stopTrack() async {
    await _musicService.stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _musicService,
      builder: (context, child) {
        // Update rotation animation based on playing state
        if (_musicService.isPlaying) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
        } else {
          _rotationController.stop();
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.currentTheme.primaryColor,
            widget.currentTheme.accentColor,
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.library_music, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Music Player',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    final categories = _musicService.categories;

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.currentTheme.primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: widget.currentTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : widget.currentTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final isSelected = _musicService.currentTrack?.id == track.id;
          final isPlaying = isSelected && _musicService.isPlaying;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.currentTheme.primaryColor.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: widget.currentTheme.primaryColor.withOpacity(0.3),
                    )
                  : null,
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              leading: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.currentTheme.primaryColor
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isPlaying && isSelected
                    ? AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * 3.14159,
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 16,
                            ),
                          );
                        },
                      )
                    : Icon(
                        isSelected ? Icons.music_note : Icons.play_arrow,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 16,
                      ),
              ),
              title: Text(
                track.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? widget.currentTheme.primaryColor
                      : widget.currentTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      track.artist,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.currentTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPlaying ? 'Playing' : 'Paused',
                        style: TextStyle(
                          fontSize: 8,
                          color: isPlaying
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Text(
                MusicService.formatDuration(track.duration),
                style: TextStyle(
                  fontSize: 10,
                  color: widget.currentTheme.textSecondary,
                ),
              ),
              onTap: () => _playTrack(track),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPlayer() {
    final track = _musicService.currentTrack!;
    final progress = _musicService.progress;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Track Info + Volume Control
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album Art
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.currentTheme.primaryColor,
                      widget.currentTheme.accentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: widget.currentTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _musicService.isPlaying
                    ? AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * 3.14159,
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 20,
                            ),
                          );
                        },
                      )
                    : Icon(Icons.music_note, color: Colors.white, size: 20),
              ),

              const SizedBox(width: 12),

              // Track Info (Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.currentTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.currentTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Volume Control (Top Right)
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.currentTheme.primaryColor.withOpacity(0.1),
                      widget.currentTheme.accentColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.currentTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _musicService.toggleMute(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _musicService.isMuted
                              ? Colors.red.withOpacity(0.15)
                              : widget.currentTheme.primaryColor.withOpacity(
                                  0.15,
                                ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _musicService.isMuted
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: _musicService.isMuted
                              ? Colors.red[600]
                              : widget.currentTheme.primaryColor,
                          size: 14,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 4,
                          ),
                          activeTrackColor: widget.currentTheme.primaryColor,
                          inactiveTrackColor: widget.currentTheme.primaryColor
                              .withOpacity(0.3),
                          thumbColor: widget.currentTheme.primaryColor,
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: _musicService.volume,
                          onChanged: (value) => _musicService.setVolume(value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Control Buttons Row (Centered under track info)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop Button
              GestureDetector(
                onTap: _stopTrack,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.stop, color: Colors.red[600], size: 16),
                ),
              ),

              const SizedBox(width: 16),

              // Play/Pause Button (Larger, more prominent)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.currentTheme.primaryColor,
                        widget.currentTheme.accentColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: widget.currentTheme.primaryColor.withOpacity(
                          0.4,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isLoading
                        ? Icons.hourglass_empty
                        : (_musicService.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Placeholder for symmetry (or add another control)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.currentTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: widget.currentTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.favorite_border,
                  color: widget.currentTheme.primaryColor.withOpacity(0.6),
                  size: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress Bar Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Time labels and slider
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.currentTheme.primaryColor.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        MusicService.formatDuration(
                          _musicService.currentPosition,
                        ),
                        style: TextStyle(
                          fontSize: 9,
                          color: widget.currentTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            activeTrackColor: widget.currentTheme.primaryColor,
                            inactiveTrackColor: widget.currentTheme.primaryColor
                                .withOpacity(0.2),
                            thumbColor: widget.currentTheme.primaryColor,
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: 10,
                            ),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final position = Duration(
                                milliseconds:
                                    (value *
                                            _musicService
                                                .totalDuration
                                                .inMilliseconds)
                                        .round(),
                              );
                              _musicService.seekTo(position);
                            },
                          ),
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.currentTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        MusicService.formatDuration(
                          _musicService.totalDuration,
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.currentTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
