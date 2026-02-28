import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/media_item.dart';
import '../models/schedule.dart';
import '../models/app_setting.dart';

class SupabaseService {
  static SupabaseService? _instance;
  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get _client => Supabase.instance.client;

  // =============================================
  // MEDIA OPERATIONS
  // =============================================

  /// Fetch all active media items ordered by display_order
  Future<List<MediaItem>> fetchActiveMedia() async {
    try {
      final response = await _client
          .from('media')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((item) => MediaItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching active media: $e');
      return [];
    }
  }

  /// Fetch all media items (active + inactive) for admin
  Future<List<MediaItem>> fetchAllMedia() async {
    try {
      final response = await _client
          .from('media')
          .select()
          .order('display_order', ascending: true);

      return (response as List)
          .map((item) => MediaItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching all media: $e');
      return [];
    }
  }

  /// Real-time stream of media changes
  Stream<List<MediaItem>> mediaStream() {
    return _client
        .from('media')
        .stream(primaryKey: ['id'])
        .order('display_order', ascending: true)
        .map((data) {
          // Deduplicate by id to prevent duplicate key errors
          final seen = <String>{};
          final items = <MediaItem>[];
          for (final item in data) {
            final media = MediaItem.fromJson(item);
            if (media.isActive && !seen.contains(media.id)) {
              seen.add(media.id);
              items.add(media);
            }
          }
          return items;
        });
  }

  /// Insert new media record — rethrows so UI can show real error
  Future<MediaItem?> insertMedia(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.from('media').insert(data).select().single();
      return MediaItem.fromJson(response);
    } catch (e) {
      print('Error inserting media: $e');
      rethrow;
    }
  }

  /// Update media record
  Future<bool> updateMedia(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('media').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Error updating media: $e');
      return false;
    }
  }

  /// Delete media record and its storage file
  Future<bool> deleteMedia(String id, String bucketPath) async {
    try {
      // Delete storage file
      if (bucketPath.isNotEmpty) {
        try {
          await _client.storage.from('media-assets').remove([bucketPath]);
        } catch (_) {
          // Ignore storage errors - file may not exist
        }
      }
      // Delete DB record
      await _client.from('media').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting media: $e');
      return false;
    }
  }

  /// Toggle media active status
  Future<bool> toggleMediaActive(String id, bool isActive) async {
    return updateMedia(id, {'is_active': isActive});
  }

  // =============================================
  // STORAGE OPERATIONS
  // =============================================

  /// Upload a file to Supabase Storage — rethrows so UI can show real error
  Future<String?> uploadFile(
      String fileName, Uint8List fileBytes, String mimeType) async {
    try {
      final path = 'uploads/$fileName';
      await _client.storage.from('media-assets').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );
      final url = _client.storage.from('media-assets').getPublicUrl(path);
      return url;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  /// Test connection — tries to query the media table
  Future<String> testConnection() async {
    try {
      final response = await _client.from('media').select().limit(1);
      return 'DB OK: media table accessible (${(response as List).length} rows returned)';
    } catch (e) {
      return 'DB ERROR: $e';
    }
  }

  /// Test storage — tries to list files in bucket
  Future<String> testStorage() async {
    try {
      final files = await _client.storage.from('media-assets').list(path: 'uploads');
      return 'Storage OK: media-assets bucket accessible (${files.length} files)';
    } catch (e) {
      return 'Storage ERROR: $e';
    }
  }

  // =============================================
  // SCHEDULE OPERATIONS
  // =============================================

  /// Fetch all active schedules
  Future<List<Schedule>> fetchActiveSchedules() async {
    try {
      final response = await _client
          .from('schedules')
          .select()
          .eq('is_active', true)
          .order('start_time', ascending: true);

      return (response as List)
          .map((item) => Schedule.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching schedules: $e');
      return [];
    }
  }

  /// Fetch all schedules
  Future<List<Schedule>> fetchAllSchedules() async {
    try {
      final response = await _client
          .from('schedules')
          .select()
          .order('start_time', ascending: true);

      return (response as List)
          .map((item) => Schedule.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching all schedules: $e');
      return [];
    }
  }

  /// Real-time stream of schedules
  Stream<List<Schedule>> schedulesStream() {
    return _client
        .from('schedules')
        .stream(primaryKey: ['id'])
        .order('start_time', ascending: true)
        .map((data) => data
            .map((item) => Schedule.fromJson(item))
            .where((item) => item.isActive)
            .toList());
  }

  /// Insert a new schedule
  Future<bool> insertSchedule(Map<String, dynamic> data) async {
    try {
      await _client.from('schedules').insert(data);
      return true;
    } catch (e) {
      print('Error inserting schedule: $e');
      return false;
    }
  }

  /// Toggle schedule active status
  Future<bool> toggleSchedule(String id, bool isActive) async {
    try {
      await _client
          .from('schedules')
          .update({'is_active': isActive}).eq('id', id);
      return true;
    } catch (e) {
      print('Error toggling schedule: $e');
      return false;
    }
  }

  /// Delete a schedule
  Future<bool> deleteSchedule(String id) async {
    try {
      await _client.from('schedules').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  // =============================================
  // APP SETTINGS OPERATIONS
  // =============================================

  /// Fetch all settings as map
  Future<Map<String, AppSetting>> fetchSettings() async {
    try {
      final response = await _client.from('app_settings').select();

      final settings = <String, AppSetting>{};
      for (final item in response as List) {
        final setting = AppSetting.fromJson(item);
        settings[setting.key] = setting;
      }
      return settings;
    } catch (e) {
      print('Error fetching settings: $e');
      return {};
    }
  }

  /// Fetch settings as a list (for admin)
  Future<List<AppSetting>> fetchSettingsList() async {
    try {
      final response = await _client.from('app_settings').select();
      return (response as List)
          .map((item) => AppSetting.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching settings list: $e');
      return [];
    }
  }

  /// Get a single setting value
  Future<String?> getSetting(String key) async {
    try {
      final settings = await fetchSettings();
      return settings[key]?.stringValue;
    } catch (e) {
      print('Error getting setting $key: $e');
      return null;
    }
  }

  /// Update a setting value
  Future<bool> updateSetting(String key, dynamic value) async {
    try {
      await _client
          .from('app_settings')
          .update({'value': value}).eq('key', key);
      return true;
    } catch (e) {
      print('Error updating setting: $e');
      return false;
    }
  }

  /// Real-time stream of settings
  Stream<Map<String, AppSetting>> settingsStream() {
    return _client
        .from('app_settings')
        .stream(primaryKey: ['id']).map((data) {
      final settings = <String, AppSetting>{};
      for (final item in data) {
        final setting = AppSetting.fromJson(item);
        settings[setting.key] = setting;
      }
      return settings;
    });
  }

  // =============================================
  // PLAYBACK LOG
  // =============================================

  /// Log a playback event
  Future<void> logPlayback(String mediaId, {String? deviceId}) async {
    try {
      await _client.from('playback_log').insert({
        'media_id': mediaId,
        'device_id': deviceId ?? 'tv-app',
      });
    } catch (e) {
      print('Error logging playback: $e');
    }
  }
}
