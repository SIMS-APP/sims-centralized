import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/media_item.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class AdminMediaScreen extends StatefulWidget {
  const AdminMediaScreen({super.key});

  @override
  State<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends State<AdminMediaScreen> {
  final SupabaseService _service = SupabaseService.instance;
  List<MediaItem> _media = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    setState(() => _loading = true);
    _media = await _service.fetchAllMedia();
    setState(() => _loading = false);
  }

  /// Show bottom sheet to choose upload method
  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(AppConstants.surfaceColor),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add Media',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading:
                  const Icon(Icons.upload_file, color: Colors.blue, size: 28),
              title: const Text('Pick File from Device',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text('Select image or video from storage',
                  style: TextStyle(color: Colors.grey[500])),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.link, color: Colors.orange, size: 28),
              title: const Text('Add by URL',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text('Enter a direct link to image or video',
                  style: TextStyle(color: Colors.grey[500])),
              onTap: () {
                Navigator.pop(ctx);
                _addByUrl();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'mp4',
          'webm',
          'mov'
        ],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // Read bytes — try withData first, fall back to path
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && file.path != null) {
        try {
          fileBytes = await File(file.path!).readAsBytes();
        } catch (e) {
          print('Error reading file from path: $e');
        }
      }

      if (fileBytes == null) {
        _showSnack('Could not read file data. Try "Add by URL" instead.');
        return;
      }

      // Show title dialog
      final title = await _showTitleDialog(
        file.name
            .replaceAll(RegExp(r'\.[^.]+$'), '')
            .replaceAll(RegExp(r'[-_]'), ' '),
      );
      if (title == null || title.isEmpty) return;

      setState(() => _uploading = true);

      // Determine type and mime
      final ext = file.extension?.toLowerCase() ?? '';
      final isVideo = ['mp4', 'webm', 'mov'].contains(ext);
      final type = isVideo ? 'video' : 'image';
      final mimeType = _getMimeType(ext);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // Upload to Supabase Storage
      final url = await _service.uploadFile(fileName, fileBytes, mimeType);

      // Insert DB record
      await _service.insertMedia({
        'title': title,
        'type': type,
        'url': url!,
        'bucket_path': 'uploads/$fileName',
        'duration_seconds': isVideo ? 30 : 10,
        'file_size_bytes': file.size,
        'mime_type': mimeType,
        'is_active': true,
        'display_order': _media.length,
      });

      _showSnack('Uploaded successfully!');
      await _fetchMedia();
    } catch (e) {
      _showError('Upload failed', e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Add media by direct URL — works on Android TV and any device
  Future<void> _addByUrl() async {
    final urlController = TextEditingController();
    final titleController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppConstants.surfaceColor),
        title:
            const Text('Add Media by URL', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  hintText: 'e.g. Hospital Welcome Ad',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color(AppConstants.primaryColor)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Media URL',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  hintText: 'https://example.com/image.jpg',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color(AppConstants.primaryColor)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Supports: jpg, png, gif, mp4, webm, mov',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColor),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final url = urlController.text.trim();
    final title = titleController.text.trim();
    if (url.isEmpty || title.isEmpty) {
      _showSnack('Title and URL are required');
      return;
    }

    setState(() => _uploading = true);
    try {
      // Determine type from URL extension
      final ext = url.split('.').last.split('?').first.toLowerCase();
      final isVideo = ['mp4', 'webm', 'mov'].contains(ext);
      final type = isVideo ? 'video' : 'image';

      await _service.insertMedia({
        'title': title,
        'type': type,
        'url': url,
        'bucket_path': '',
        'duration_seconds': isVideo ? 30 : 10,
        'mime_type': _getMimeType(ext),
        'is_active': true,
        'display_order': _media.length,
      });

      _showSnack('Media added successfully!');
      await _fetchMedia();
    } catch (e) {
      _showError('Add by URL failed', e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _showTitleDialog(String defaultTitle) async {
    final controller = TextEditingController(text: defaultTitle);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppConstants.surfaceColor),
        title: const Text('Media Title', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter a title for this media',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(AppConstants.primaryColor)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColor),
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(MediaItem item) async {
    final success = await _service.toggleMediaActive(item.id, !item.isActive);
    if (success) {
      await _fetchMedia();
    } else {
      _showSnack('Failed to toggle status');
    }
  }

  Future<void> _deleteMedia(MediaItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppConstants.surfaceColor),
        title: const Text('Delete Media', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${item.title}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _service.deleteMedia(item.id, item.bucketPath);
    if (success) {
      _showSnack('Deleted "${item.title}"');
      await _fetchMedia();
    } else {
      _showSnack('Failed to delete');
    }
  }

  String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Show a full error dialog so user can read and copy the error
  void _showError(String title, String error) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppConstants.surfaceColor),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: SingleChildScrollView(
          child: SelectableText(
            error,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Test Supabase connection — DB + Storage
  Future<void> _testConnection() async {
    _showSnack('Testing connection...');
    final dbResult = await _service.testConnection();
    final storageResult = await _service.testStorage();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppConstants.surfaceColor),
        title: const Text('Connection Test', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  dbResult.startsWith('DB OK') ? Icons.check_circle : Icons.error,
                  color: dbResult.startsWith('DB OK') ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text('Database', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 16),
              child: SelectableText(dbResult, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            Row(
              children: [
                Icon(
                  storageResult.startsWith('Storage OK') ? Icons.check_circle : Icons.error,
                  color: storageResult.startsWith('Storage OK') ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text('Storage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: SelectableText(storageResult, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Media Management',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const Spacer(),
              // Test connection button
              OutlinedButton.icon(
                onPressed: _testConnection,
                icon: const Icon(Icons.wifi_find, size: 18),
                label: const Text('Test'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              if (_uploading)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _showUploadOptions,
                icon: const Icon(Icons.add),
                label: Text(_uploading ? 'Uploading...' : 'Add Media'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_media.length} items • ${_media.where((m) => m.isActive).length} active',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Media list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _media.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.perm_media_outlined,
                                size: 64, color: Colors.grey[700]),
                            const SizedBox(height: 16),
                            Text(
                              'No media uploaded yet',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Upload Media" to add images or videos',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMedia,
                        child: ListView.builder(
                          itemCount: _media.length,
                          itemBuilder: (ctx, index) =>
                              _buildMediaCard(_media[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(MediaItem item) {
    return Card(
      color: const Color(AppConstants.surfaceColor),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: item.isVideo
              ? const Icon(Icons.videocam, color: Colors.purple, size: 28)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.url,
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image,
                        color: Colors.orange,
                        size: 28),
                  ),
                ),
        ),
        title: Text(item.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${item.type.toUpperCase()} • ${item.durationSeconds}s • Order: ${item.displayOrder}',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active toggle
            Switch(
              value: item.isActive,
              onChanged: (_) => _toggleActive(item),
              activeThumbColor: Colors.green,
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteMedia(item),
            ),
          ],
        ),
      ),
    );
  }
}
