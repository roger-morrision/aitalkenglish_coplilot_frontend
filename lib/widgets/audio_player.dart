import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
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
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
      
      // Set error handler
      _manualTts!.setErrorHandler((message) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    }
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      // Stop current playback
      await _manualTts?.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // Start playback
      setState(() {
        _isPlaying = true;
      });
      
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
          await _manualTts?.speak(cleanText);
        } else {
          setState(() {
            _isPlaying = false;
          });
        }
      } catch (e) {
        print('TTS Error: $e');
        setState(() {
          _isPlaying = false;
        });
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
    // Don't dispose the static TTS instance as it's shared
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
