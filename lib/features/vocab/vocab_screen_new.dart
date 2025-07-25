import 'package:flutter/material.dart';

class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  List<Map<String, String>> _vocab = [];
  bool _loading = false;
  String? _error;
  String? _lastAdded;

  Future<void> _fetchVocab() async {
    setState(() => _loading = true);
    try {
      // For now, use local data until backend is implemented
      setState(() {
        _vocab = [
          {"word": "Serendipity", "meaning": "A pleasant surprise"},
          {"word": "Ephemeral", "meaning": "Lasting for a very short time"},
          {"word": "Ubiquitous", "meaning": "Present everywhere"},
        ];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load vocabulary.';
      });
    }
  }

  Future<void> _addVocab() async {
    final word = _wordController.text.trim();
    final meaning = _meaningController.text.trim();
    if (word.isEmpty || meaning.isEmpty) return;
    
    setState(() => _loading = true);
    
    try {
      // Add to local list for now
      setState(() {
        _vocab.add({"word": word, "meaning": meaning});
        _lastAdded = word;
      });
      
      _wordController.clear();
      _meaningController.clear();
      
      // Show success dialog
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Word Added'),
              content: Text('"$word" has been added to your vocabulary.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to add word.';
      });
    }
    
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _fetchVocab();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add new word section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _wordController,
                      decoration: const InputDecoration(
                        labelText: 'New Word',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _meaningController,
                      decoration: const InputDecoration(
                        labelText: 'Meaning',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _addVocab,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Add Word'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            // Vocabulary list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _vocab.length,
                      itemBuilder: (context, index) {
                        final item = _vocab[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              item['word']!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(item['meaning']!),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _vocab.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    super.dispose();
  }
}
