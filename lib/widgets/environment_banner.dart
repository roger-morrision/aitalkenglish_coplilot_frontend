import 'package:flutter/material.dart';
import '../config/api_config.dart';

class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show banner in non-production environments
    if (ApiConfig.isProduction) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: _getEnvironmentColor(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEnvironmentIcon(),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${ApiConfig.environmentName} Environment',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Backend: ${ApiConfig.baseUrl}',
            child: const Icon(
              Icons.info_outline,
              color: Colors.white70,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEnvironmentColor() {
    switch (ApiConfig.currentEnvironment) {
      case Environment.development:
        return Colors.green;
      case Environment.staging:
        return Colors.orange;
      case Environment.production:
        return Colors.blue; // Won't be shown but just in case
    }
  }

  IconData _getEnvironmentIcon() {
    switch (ApiConfig.currentEnvironment) {
      case Environment.development:
        return Icons.code;
      case Environment.staging:
        return Icons.science;
      case Environment.production:
        return Icons.public;
    }
  }
}

class EnvironmentDebugInfo extends StatelessWidget {
  const EnvironmentDebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ApiConfig.enableDebugLogging) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔧 Debug Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Environment', ApiConfig.environmentName),
            _buildInfoRow('Backend URL', ApiConfig.baseUrl),
            _buildInfoRow('API Timeout', '${ApiConfig.apiTimeout.inSeconds}s'),
            _buildInfoRow('Debug Logging', ApiConfig.enableDebugLogging ? 'Enabled' : 'Disabled'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ApiConfig.printConfig();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuration printed to console'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('Print Config to Console'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
