import 'package:flutter/material.dart';
import '../services/app_settings.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsDialog({super.key, this.onSettingsChanged});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _urlController;
  late InferenceMode _selectedMode;
  bool _isValidUrl = true;
  final AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _settings.apiBaseUrl);
    _selectedMode = _settings.inferenceMode;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _validateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _saveSettings() {
    // If API mode is selected, validate URL
    if (_selectedMode == InferenceMode.api) {
      final url = _urlController.text.trim();
      if (!_validateUrl(url)) {
        setState(() {
          _isValidUrl = false;
        });
        return;
      }
      _settings.setApiBaseUrl(url);
    }

    _settings.setInferenceMode(_selectedMode);
    Navigator.of(context).pop();

    widget.onSettingsChanged?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_selectedMode == InferenceMode.tflite
            ? 'Using on-device TFLite model'
            : 'Using API server for inference'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Settings',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Inference Mode Section
              Text(
                'Inference Mode',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              // TFLite Option
              _buildModeOption(
                context,
                title: 'On-Device (TFLite)',
                subtitle: 'Fast, offline, no server needed',
                icon: Icons.smartphone_rounded,
                isSelected: _selectedMode == InferenceMode.tflite,
                onTap: () {
                  setState(() {
                    _selectedMode = InferenceMode.tflite;
                  });
                },
              ),

              const SizedBox(height: 8),

              // API Option
              _buildModeOption(
                context,
                title: 'Server API',
                subtitle: 'Requires network & running server',
                icon: Icons.cloud_rounded,
                isSelected: _selectedMode == InferenceMode.api,
                onTap: () {
                  setState(() {
                    _selectedMode = InferenceMode.api;
                  });
                },
              ),

              // API URL field (only show when API mode is selected)
              if (_selectedMode == InferenceMode.api) ...[
                const SizedBox(height: 20),

                Text(
                  'Server URL',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'http://192.168.1.96:5000',
                    filled: true,
                    fillColor:
                        colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isValidUrl
                            ? colorScheme.outline.withOpacity(0.3)
                            : colorScheme.error,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    errorText: _isValidUrl ? null : 'Please enter a valid URL',
                    prefixIcon: Icon(
                      Icons.link_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  onChanged: (value) {
                    if (!_isValidUrl) {
                      setState(() {
                        _isValidUrl = true;
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use your computer\'s IP address and ensure the Flask server is running.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _saveSettings,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.5)
              : colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.2)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}