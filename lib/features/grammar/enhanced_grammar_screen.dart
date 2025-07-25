import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _correction = '';
  bool _loading = false;
  String? _error;
  List<GrammarError> _grammarErrors = [];
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _checkGrammar() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _loading = true;
      _error = null;
      _grammarErrors.clear();
    });
    
    try {
      final result = await ApiService.checkGrammar(text);
      
      // Parse grammar errors from result
      final errors = _parseGrammarErrors(text, result);
      
      setState(() {
        _correction = result;
        _grammarErrors = errors;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to check grammar: ${e.toString()}';
      });
    }
  }

  List<GrammarError> _parseGrammarErrors(String original, String corrected) {
    // Simple diff algorithm to find errors
    List<GrammarError> errors = [];
    
    // For demo purposes, create some mock errors
    if (original.toLowerCase().contains('their is')) {
      int index = original.toLowerCase().indexOf('their is');
      errors.add(GrammarError(
        start: index,
        end: index + 8,
        originalText: 'their is',
        suggestion: 'there is',
        errorType: 'Grammar',
        description: 'Use "there is" instead of "their is"',
      ));
    }
    
    if (original.toLowerCase().contains('alot')) {
      int index = original.toLowerCase().indexOf('alot');
      errors.add(GrammarError(
        start: index,
        end: index + 4,
        originalText: 'alot',
        suggestion: 'a lot',
        errorType: 'Spelling',
        description: '"A lot" should be written as two words',
      ));
    }
    
    return errors;
  }

  void _showErrorPopover(GrammarError error, Offset position) {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy - 100,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      error.errorType == 'Grammar' ? Icons.edit : Icons.spellcheck,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      error.errorType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  error.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '\"${error.originalText}\" → \"${error.suggestion}\"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _removeOverlay(),
                      child: const Text('Dismiss'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _applySuggestion(error);
                        _removeOverlay();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    
    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _removeOverlay();
    });
  }

  void _applySuggestion(GrammarError error) {
    final text = _controller.text;
    final newText = text.replaceRange(error.start, error.end, error.suggestion);
    _controller.text = newText;
    
    // Remove the applied error from the list
    setState(() {
      _grammarErrors.removeWhere((e) => e.start == error.start);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar Check'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => _removeOverlay(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter text to check:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildHighlightedTextField(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _checkGrammar,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.spellcheck),
                              label: Text(_loading ? 'Checking...' : 'Check Grammar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _grammarErrors.clear();
                                _correction = '';
                                _error = null;
                              });
                              _removeOverlay();
                            },
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear text',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (_grammarErrors.isEmpty && _correction.isNotEmpty && _correction == _controller.text)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Great! No grammar errors found.',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (_grammarErrors.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Found ${_grammarErrors.length} issue${_grammarErrors.length == 1 ? '' : 's'}:',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(_grammarErrors.map((error) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  error.errorType == 'Grammar' ? Icons.edit : Icons.spellcheck,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        error.description,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\"${error.originalText}\" → \"${error.suggestion}\"',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _applySuggestion(error),
                                  child: const Text('Apply'),
                                ),
                              ],
                            ),
                          ),
                        ))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedTextField() {
    return Stack(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Type your text here...',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        if (_grammarErrors.isNotEmpty)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                // Find which error was tapped (simplified approach)
                for (final error in _grammarErrors) {
                  _showErrorPopover(error, details.globalPosition);
                  break; // Show first error for demo
                }
              },
              child: CustomPaint(
                painter: GrammarHighlightPainter(_controller.text, _grammarErrors),
              ),
            ),
          ),
      ],
    );
  }
}

class GrammarError {
  final int start;
  final int end;
  final String originalText;
  final String suggestion;
  final String errorType;
  final String description;

  GrammarError({
    required this.start,
    required this.end,
    required this.originalText,
    required this.suggestion,
    required this.errorType,
    required this.description,
  });
}

class GrammarHighlightPainter extends CustomPainter {
  final String text;
  final List<GrammarError> errors;

  GrammarHighlightPainter(this.text, this.errors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // This is a simplified highlighting approach
    // In a real implementation, you'd need to calculate text positions more precisely
    for (int i = 0; i < errors.length; i++) {
      final rect = Rect.fromLTWH(
        0,
        20.0 + (i * 25.0), // Approximate line height with offset
        size.width,
        2.0, // Underline thickness
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
