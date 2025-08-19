import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../config/env_config.dart';
import '../../config/api_config.dart';

class EnvironmentSettingsScreen extends StatefulWidget {
  const EnvironmentSettingsScreen({super.key});

  @override
  State<EnvironmentSettingsScreen> createState() => _EnvironmentSettingsScreenState();
}

class _EnvironmentSettingsScreenState extends State<EnvironmentSettingsScreen> {
  String _selectedEnvironment = EnvConfig.apiEnvironment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Environment Status
            _buildCurrentEnvironmentCard(),
            const SizedBox(height: 24),

            // Environment Selection (only in debug mode)
            if (kDebugMode) ...[
              _buildEnvironmentSelector(),
              const SizedBox(height: 24),
            ],

            // API Configuration
            _buildApiConfigurationCard(),
            const SizedBox(height: 24),

            // Environment URLs
            _buildEnvironmentUrlsCard(),
            const SizedBox(height: 24),

            // Actions
            if (kDebugMode) _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentEnvironmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Environment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Environment', EnvConfig.apiEnvironment.toUpperCase()),
            _buildInfoRow('Backend URL', EnvConfig.currentBackendUrl),
            _buildInfoRow('Status', EnvConfig.isLoaded ? 'Loaded' : 'Not Loaded'),
            if (kDebugMode) ...[
              _buildInfoRow('Debug Mode', 'Enabled'),
              _buildInfoRow('OpenRouter API', EnvConfig.openRouterApiKey.isNotEmpty ? 'Configured' : 'Not Set'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horizontal_circle,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Switch Environment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Change the backend environment (Debug mode only)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...['development', 'staging', 'production'].map((env) {
              return RadioListTile<String>(
                title: Text(env.toUpperCase()),
                subtitle: Text(EnvConfig.allUrls[env] ?? ''),
                value: env,
                groupValue: _selectedEnvironment,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedEnvironment = value;
                    });
                    EnvConfig.switchToEnvironment(value);
                    _showSnackBar('Environment switched to $value');
                  }
                },
                activeColor: Colors.deepPurple,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildApiConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.api,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text(
                  'API Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Chat Timeout', '${EnvConfig.chatTimeoutSeconds}s'),
            _buildInfoRow('Suggestions Timeout', '${EnvConfig.suggestionsTimeoutSeconds}s'),
            _buildInfoRow('General API Timeout', '${EnvConfig.apiTimeoutSeconds}s'),
            _buildInfoRow('Server Port', '${EnvConfig.port}'),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentUrlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Environment URLs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...EnvConfig.allUrls.entries.map((entry) {
              final isActive = entry.key == EnvConfig.apiEnvironment;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.deepPurple.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? Colors.deepPurple : Colors.grey.withOpacity(0.3),
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (isActive) 
                      Icon(
                        Icons.radio_button_checked,
                        color: Colors.deepPurple,
                        size: 16,
                      )
                    else
                      Icon(
                        Icons.radio_button_unchecked,
                        color: Colors.grey,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.toUpperCase(),
                            style: TextStyle(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? Colors.deepPurple : Colors.black,
                            ),
                          ),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Debug Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  EnvConfig.printConfig();
                  ApiConfig.printConfig();
                  _showSnackBar('Configuration printed to console');
                },
                icon: const Icon(Icons.print),
                label: const Text('Print Configuration to Console'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final isValid = EnvConfig.validateRequired();
                  _showSnackBar(isValid ? 'All required variables are set' : 'Some required variables are missing');
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Validate Configuration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ApiConfig.reloadEnv();
                  setState(() {
                    _selectedEnvironment = EnvConfig.apiEnvironment;
                  });
                  _showSnackBar('Environment reloaded');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reload Environment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
