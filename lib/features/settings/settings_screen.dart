import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<AIModel> _availableModels = [];
  AIModel? _selectedModel;
  bool _isLoading = true;
  bool _isUpdating = false;
  
  // Voice settings
  bool _voiceAutoplayEnabled = true;
  bool _voiceInputEnabled = true;
  bool _isVoiceSettingsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await Future.wait([
      _loadModels(),
      _loadVoiceSettings(),
    ]);
  }

  Future<void> _loadVoiceSettings() async {
    try {
      setState(() => _isVoiceSettingsLoading = true);
      
      final voiceSettings = await ApiService.getVoiceSettings();
      
      setState(() {
        _voiceAutoplayEnabled = voiceSettings['voice_autoplay_enabled'] ?? true;
        _voiceInputEnabled = voiceSettings['voice_input_enabled'] ?? true;
        _isVoiceSettingsLoading = false;
      });
    } catch (e) {
      print('Error loading voice settings: $e');
      setState(() => _isVoiceSettingsLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load voice settings: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _updateVoiceSettings({bool? autoplay, bool? voiceInput}) async {
    try {
      setState(() => _isVoiceSettingsLoading = true);
      
      final newAutoplay = autoplay ?? _voiceAutoplayEnabled;
      final newVoiceInput = voiceInput ?? _voiceInputEnabled;
      
      await ApiService.updateVoiceSettings(
        voiceAutoplayEnabled: newAutoplay,
        voiceInputEnabled: newVoiceInput,
      );
      
      setState(() {
        _voiceAutoplayEnabled = newAutoplay;
        _voiceInputEnabled = newVoiceInput;
        _isVoiceSettingsLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating voice settings: $e');
      setState(() => _isVoiceSettingsLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update voice settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadModels() async {
    try {
      setState(() => _isLoading = true);
      
      // Load available models
      final modelsData = await ApiService.getAvailableModels();
      final models = (modelsData['available'] as List)
          .map((model) => AIModel.fromJson(model))
          .toList();
      
      // Load current selected model
      final currentModelData = await ApiService.getCurrentModel();
      final currentModel = AIModel.fromJson(currentModelData['model_info']);
      
      setState(() {
        _availableModels = models;
        _selectedModel = currentModel;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading models: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load AI models: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectModel(AIModel model) async {
    if (_selectedModel?.id == model.id) return;
    
    try {
      setState(() => _isUpdating = true);
      
      await ApiService.selectModel(model.id);
      
      setState(() {
        _selectedModel = model;
        _isUpdating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI model updated to ${model.name}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Test',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(); // Go back to chat to test
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error selecting model: $e');
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI Model Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading AI models...'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Model Info
                        if (_selectedModel != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Currently Selected',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedModel!.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedModel!.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildProviderChip(_selectedModel!.provider),
                                    const SizedBox(width: 8),
                                    _buildTierChip(_selectedModel!.tier),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Voice Settings Section
                        Text(
                          'Voice Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Configure voice input and audio playback for AI responses.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Voice Settings Cards
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Auto-play AI Responses
                              Row(
                                children: [
                                  Icon(
                                    Icons.volume_up,
                                    color: Colors.blue[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Auto-play AI Responses',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Automatically speak AI responses out loud',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _voiceAutoplayEnabled,
                                    onChanged: _isVoiceSettingsLoading ? null : (value) {
                                      _updateVoiceSettings(autoplay: value);
                                    },
                                    activeColor: Colors.green[600],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              // Voice Input
                              Row(
                                children: [
                                  Icon(
                                    Icons.mic,
                                    color: Colors.orange[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Voice Input',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Enable microphone button for speech-to-text',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _voiceInputEnabled,
                                    onChanged: _isVoiceSettingsLoading ? null : (value) {
                                      _updateVoiceSettings(voiceInput: value);
                                    },
                                    activeColor: Colors.green[600],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Available Models
                        Text(
                          'Available AI Models',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select an AI model to use for chat responses and suggestions. All features will use the same model.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Models List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _availableModels.length,
                          itemBuilder: (context, index) {
                            final model = _availableModels[index];
                            final isSelected = _selectedModel?.id == model.id;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _isUpdating ? null : () => _selectModel(model),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.deepPurple[50] : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected 
                                            ? Colors.deepPurple[300]! 
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                model.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected 
                                                      ? Colors.deepPurple[800] 
                                                      : Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green[600],
                                                size: 24,
                                              ),
                                            ] else if (_isUpdating) ...[
                                              const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          model.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected 
                                                ? Colors.deepPurple[700] 
                                                : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            _buildProviderChip(model.provider),
                                            const SizedBox(width: 8),
                                            _buildTierChip(model.tier),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Info Panel
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Model Information',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '• All AI features (chat, suggestions, grammar) will use the same selected model\n'
                                '• Free models have usage limits and may experience rate limiting\n'
                                '• Model changes take effect immediately for new conversations\n'
                                '• Different models may have varying response styles and capabilities',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber[800],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderChip(String provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Text(
        provider,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildTierChip(String tier) {
    final isFreeTier = tier.toLowerCase() == 'free';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFreeTier ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFreeTier ? Colors.green[300]! : Colors.orange[300]!,
        ),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isFreeTier ? Colors.green[800] : Colors.orange[800],
        ),
      ),
    );
  }
}

class AIModel {
  final String id;
  final String name;
  final String description;
  final String provider;
  final String tier;

  AIModel({
    required this.id,
    required this.name,
    required this.description,
    required this.provider,
    required this.tier,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      provider: json['provider'] ?? '',
      tier: json['tier'] ?? '',
    );
  }
}
