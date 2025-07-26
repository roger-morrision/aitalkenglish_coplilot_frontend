import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;

class AudioPlayButton extends StatefulWidget {
  final String text;
  final double size;
  final Color? color;
  final bool mini;

  const AudioPlayButton({
    super.key,
    required this.text,
    this.size = 20,
    this.color,
    this.mini = false,
  });

  @override
  State<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton> {
  static FlutterTts? _manualTts; // Separate TTS instance for manual playback
  static _AudioPlayButtonState? _currentPlayingWidget; // Track which widget is playing
  static final Set<_AudioPlayButtonState> _allWidgets = {}; // Track all audio widgets
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
    _allWidgets.add(this); // Register this widget
    _initTts();
  }

  Future<void> _initTts() async {
    if (_manualTts == null) {
      _manualTts = FlutterTts();
      
      // Configure TTS for manual playback
      await _manualTts!.setLanguage('en-US');
      await _manualTts!.setSpeechRate(0.5);
      await _manualTts!.setVolume(0.8);
      await _manualTts!.setPitch(1.0);
      
      // Set completion handler
      _manualTts!.setCompletionHandler(() {
        // Reset all widgets to normal state when audio completes
        _stopAllAudio();
      });
      
      // Set error handler
      _manualTts!.setErrorHandler((message) {
        // Reset all widgets to normal state on error
        _stopAllAudio();
      });
    }
  }

  // Static method to stop all audio and reset all widget states
  static void _stopAllAudio() {
    print('AudioPlayButton: Stopping all audio, ${_allWidgets.length} widgets registered');
    for (var widget in _allWidgets) {
      if (widget.mounted) {
        print('AudioPlayButton: Resetting widget state to false');
        widget.setState(() {
          widget._isPlaying = false;
        });
      }
    }
    _currentPlayingWidget = null;
    print('AudioPlayButton: All widgets reset, currentPlayingWidget cleared');
  }

  Future<void> _toggleAudio() async {
    print('AudioPlayButton: Toggle audio called, current state: $_isPlaying');
    
    if (_isPlaying) {
      // If this widget is playing, stop it
      print('AudioPlayButton: Stopping current playback');
      await _manualTts?.stop();
      _stopAllAudio();
    } else {
      // Stop all audio first and reset all states
      print('AudioPlayButton: Starting new playback, stopping all others first');
      await _manualTts?.stop();
      _stopAllAudio();
      
      // Now start playback for this widget
      _currentPlayingWidget = this;
      setState(() {
        _isPlaying = true;
      });
      print('AudioPlayButton: Set playing state to true, starting TTS');
      
      try {
        // Clean text for better TTS
        String cleanText = widget.text
            .replaceAll(RegExp(r'\[.*?\]'), '') // Remove [Demo Mode] tags
            .replaceAll('"', '"') // Normalize quotes
            .replaceAll('"', '"')
            .replaceAll(''', "'") // Normalize apostrophes
            .replaceAll(''', "'")
            .trim();
        
        if (cleanText.isNotEmpty) {
          print('AudioPlayButton: Speaking text: ${cleanText.substring(0, math.min(50, cleanText.length))}...');
          await _manualTts?.speak(cleanText);
        } else {
          print('AudioPlayButton: Empty text, stopping audio');
          _stopAllAudio();
        }
      } catch (e) {
        print('TTS Error: $e');
        _stopAllAudio();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mini) {
      return GestureDetector(
        onTap: _toggleAudio,
        child: Container(
          padding: const EdgeInsets.all(2),
          child: Icon(
            _isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
            size: widget.size,
            color: widget.color ?? (_isPlaying ? Colors.red[600] : Colors.grey[600]),
          ),
        ),
      );
    }

    return IconButton(
      onPressed: _toggleAudio,
      icon: _isPlaying 
          ? Icon(Icons.stop_rounded, color: Colors.red[600])
          : Icon(Icons.volume_up_rounded, color: widget.color ?? Colors.grey[600]),
      iconSize: widget.size,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: _isPlaying ? 'Stop audio' : 'Play audio',
    );
  }

  @override
  void dispose() {
    // Unregister this widget
    _allWidgets.remove(this);
    
    // Clear reference if this widget was the currently playing one
    if (_currentPlayingWidget == this) {
      _currentPlayingWidget = null;
    }
    super.dispose();
  }
}

// Helper widget for vocabulary items with audio
class VocabularyAudioItem extends StatelessWidget {
  final String word;
  final String meaning;
  final String example;

  const VocabularyAudioItem({
    super.key,
    required this.word,
    required this.meaning,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word with audio
          Row(
            children: [
              Text(
                word,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              AudioPlayButton(
                text: word,
                size: 16,
                mini: true,
                color: Colors.blue[700],
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Meaning
          Text(
            meaning,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          
          // Example with audio
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Example: $example',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AudioPlayButton(
                text: example,
                size: 14,
                mini: true,
                color: Colors.grey[600],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper widget for better versions with audio
class BetterVersionItem extends StatelessWidget {
  final String text;
  final int index;

  const BetterVersionItem({
    super.key,
    required this.text,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AudioPlayButton(
            text: text,
            size: 16,
            mini: true,
            color: Colors.green[700],
          ),
        ],
      ),
    );
  }
}
