import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  List<dynamic> _vocabList = [];
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _lastAdded;

  Future<void> _fetchVocab() async {
    setState(() => _loading = true);
    try {
      final vocab = await ApiService.getVocab();
      setState(() {
        _vocabList = vocab;
        _loading = false;
      });
  bool _loading = false;
  String? _error;
  String? _lastAdded;
      setState(() {
        _loading = false;
    setState(() => _loading = true);
      });
      final vocab = await LocalDbService.getVocab();
  }

  Future<void> _addVocab() async {
    final word = _wordController.text.trim();
    final meaning = _meaningController.text.trim();
    if (word.isEmpty || meaning.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.addVocab(word, meaning);
      _wordController.clear();
      _meaningController.clear();
      setState(() {
        _lastAdded = word;
      });
      await _fetchVocab();
      Future.delayed(const Duration(milliseconds: 300), () {
        showDialog(
          context: context,
      await LocalDbService.addVocab(word, meaning);
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
      });
    } catch (e) {
      setState(() {
        _loading = false;
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
      appBar: AppBar(title: const Text('Vocabulary Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    decoration: const InputDecoration(hintText: 'Word'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _meaningController,
                    decoration: const InputDecoration(hintText: 'Meaning'),
                  ),
                ),
                IconButton(
                  icon: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  onPressed: _loading ? null : _addVocab,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        key: ValueKey(_vocabList.length),
                        itemCount: _vocabList.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _vocabList[index];
                          final isNew = _lastAdded == item['word'];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isNew ? Colors.green[100] : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(item['word'] ?? ''),
                              subtitle: Text(item['meaning'] ?? ''),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
