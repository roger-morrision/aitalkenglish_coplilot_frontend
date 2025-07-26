import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../services/progress_service.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  final TextEditingController _controller = TextEditingController();
  String _correction = '';
  bool _loading = false;
  String? _error;

  void _checkGrammar() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Track user progress
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final currentProgress = await ProgressService.loadProgress(user.uid);
        await ProgressService.trackMessageSubmission(currentProgress, text, 'grammar');
      }
    } catch (e) {
      print('Error tracking progress: $e');
    }
    
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.checkGrammar(text);
      setState(() {
        _correction = result;
        _loading = false;
      });
      // Show popover suggestion if correction differs
      if (_correction != text) {
        Future.delayed(const Duration(milliseconds: 300), () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Suggestion'),
              content: Text(_correction),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to check grammar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grammar Correction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Enter a sentence...'),
              onSubmitted: (_) => _checkGrammar(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _checkGrammar,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Check Grammar'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _correction.isNotEmpty
                  ? Card(
                      key: ValueKey(_correction),
                      color: Colors.yellow[100],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _highlightMistakes(_controller.text, _correction),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // Simple error highlighting: show differences in red
  Widget _highlightMistakes(String original, String corrected) {
    if (original == corrected) {
      return Text(corrected);
    }
    // For demo: highlight all changed words in red
    final origWords = original.split(' ');
    final corrWords = corrected.split(' ');
    List<TextSpan> spans = [];
    for (int i = 0; i < corrWords.length; i++) {
      final word = corrWords[i];
      if (i >= origWords.length || word != origWords[i]) {
        spans.add(TextSpan(text: '$word ', style: const TextStyle(color: Colors.red)));
      } else {
        spans.add(TextSpan(text: '$word ', style: const TextStyle(color: Colors.black)));
      }
    }
    return RichText(text: TextSpan(children: spans, style: const TextStyle(fontSize: 16)));
  }
}
