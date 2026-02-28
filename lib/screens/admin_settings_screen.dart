import 'package:flutter/material.dart';
import '../models/app_setting.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final SupabaseService _service = SupabaseService.instance;
  List<AppSetting> _settings = [];
  bool _loading = true;
  String? _saving;
  final Map<String, TextEditingController> _controllers = {};

  static const _settingMeta = {
    'ad_rotation_interval': {
      'label': 'Ad Rotation Interval',
      'description': 'Seconds between ad transitions (for images)',
      'type': 'number',
    },
    'pip_enabled': {
      'label': 'PIP Mode Enabled',
      'description': 'Allow Picture-in-Picture mode on TV app',
      'type': 'bool',
    },
    'cliniqtv_package': {
      'label': 'CliniqTV Package Name',
      'description': 'Android package name of the queue management app',
      'type': 'text',
    },
    'display_mode': {
      'label': 'Default Display Mode',
      'description': 'Default display mode: fullscreen or pip',
      'type': 'select',
    },
    'marquee_text': {
      'label': 'Marquee Text',
      'description': 'Scrolling text at bottom of the TV screen',
      'type': 'text',
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() => _loading = true);
    _settings = await _service.fetchSettingsList();

    for (final setting in _settings) {
      final val = setting.stringValue;
      if (_controllers.containsKey(setting.key)) {
        _controllers[setting.key]!.text = val;
      } else {
        _controllers[setting.key] = TextEditingController(text: val);
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveSetting(String key) async {
    setState(() => _saving = key);
    final rawValue = _controllers[key]?.text ?? '';

    // Determine how to store the value
    dynamic jsonValue;
    if (rawValue == 'true') {
      jsonValue = true;
    } else if (rawValue == 'false') {
      jsonValue = false;
    } else if (int.tryParse(rawValue) != null) {
      jsonValue = '"$rawValue"'; // Store as quoted string for numbers
    } else {
      jsonValue = '"$rawValue"';
    }

    final success = await _service.updateSetting(key, jsonValue);

    if (mounted) {
      setState(() => _saving = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'Saved "$key"' : 'Failed to save "$key"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Changes are synced in real-time to all connected TV devices',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _settings.length,
                    itemBuilder: (ctx, i) => _buildSettingCard(_settings[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(AppSetting setting) {
    final meta = _settingMeta[setting.key];
    final label = meta?['label'] ?? setting.key;
    final description = meta?['description'] ?? setting.description ?? '';
    final type = meta?['type'] ?? 'text';

    return Card(
      color: const Color(AppConstants.surfaceColor),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInput(setting.key, type)),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving == setting.key
                      ? null
                      : () => _saveSetting(setting.key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    _saving == setting.key ? 'Saving...' : 'Save',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String key, String type) {
    final controller = _controllers[key];
    if (controller == null) return const SizedBox.shrink();

    if (type == 'bool') {
      return DropdownButtonFormField<String>(
        initialValue: controller.text == 'true' ? 'true' : 'false',
        dropdownColor: const Color(AppConstants.surfaceColor),
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(),
        items: const [
          DropdownMenuItem(value: 'true', child: Text('Enabled')),
          DropdownMenuItem(value: 'false', child: Text('Disabled')),
        ],
        onChanged: (val) {
          if (val != null) controller.text = val;
        },
      );
    }

    if (type == 'select') {
      return DropdownButtonFormField<String>(
        initialValue: controller.text == 'pip' ? 'pip' : 'fullscreen',
        dropdownColor: const Color(AppConstants.surfaceColor),
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(),
        items: const [
          DropdownMenuItem(
              value: 'fullscreen', child: Text('Fullscreen')),
          DropdownMenuItem(
              value: 'pip', child: Text('PIP (Picture-in-Picture)')),
        ],
        onChanged: (val) {
          if (val != null) controller.text = val;
        },
      );
    }

    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: type == 'number' ? TextInputType.number : TextInputType.text,
      decoration: _inputDecoration(),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(AppConstants.primaryColor)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
