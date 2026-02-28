import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../models/schedule.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class AdminSchedulesScreen extends StatefulWidget {
  const AdminSchedulesScreen({super.key});

  @override
  State<AdminSchedulesScreen> createState() => _AdminSchedulesScreenState();
}

class _AdminSchedulesScreenState extends State<AdminSchedulesScreen> {
  final SupabaseService _service = SupabaseService.instance;
  List<Schedule> _schedules = [];
  List<MediaItem> _media = [];
  bool _loading = true;

  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.fetchAllSchedules(),
      _service.fetchAllMedia(),
    ]);
    _schedules = results[0] as List<Schedule>;
    _media = results[1] as List<MediaItem>;
    setState(() => _loading = false);
  }

  String _getMediaTitle(String mediaId) {
    final item = _media.where((m) => m.id == mediaId).firstOrNull;
    return item?.title ?? 'Unknown';
  }

  Future<void> _showCreateDialog() async {
    if (_media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload media first before creating schedules')),
      );
      return;
    }

    String selectedMediaId = _media.first.id;
    String name = '';
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
    List<int> selectedDays = [0, 1, 2, 3, 4, 5, 6];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(AppConstants.surfaceColor),
          title: const Text('Create Schedule',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media selector
                const Text('Media', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedMediaId,
                  dropdownColor: const Color(AppConstants.surfaceColor),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  items: _media
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text('${m.title} (${m.type})'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedMediaId = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Schedule name
                const Text('Name (optional)',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., Morning Ads',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),

                // Time pickers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Time',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setDialogState(() => startTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey[700]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                style:
                                    const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Time',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setDialogState(() => endTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey[700]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                style:
                                    const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Day selector
                const Text('Days',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (i) {
                    final selected = selectedDays.contains(i);
                    return FilterChip(
                      label: Text(_dayNames[i]),
                      selected: selected,
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedDays.add(i);
                            selectedDays.sort();
                          } else {
                            selectedDays.remove(i);
                          }
                        });
                      },
                      selectedColor: const Color(AppConstants.primaryColor),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.grey,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.grey[800],
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final startStr =
                    '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                final endStr =
                    '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                final success = await _service.insertSchedule({
                  'media_id': selectedMediaId,
                  'name': name.isEmpty ? null : name,
                  'start_time': startStr,
                  'end_time': endStr,
                  'days_of_week': selectedDays,
                  'is_active': true,
                });

                if (ctx.mounted) Navigator.pop(ctx);

                if (success) {
                  _fetchData();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create schedule')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppConstants.surfaceColor),
        title:
            const Text('Delete Schedule', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete this schedule? This cannot be undone.',
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
    final success = await _service.deleteSchedule(schedule.id);
    if (success) _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Schedules',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _schedules.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule,
                                size: 64, color: Colors.grey[700]),
                            const SizedBox(height: 16),
                            Text('No schedules yet',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 18)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          itemCount: _schedules.length,
                          itemBuilder: (ctx, i) =>
                              _buildScheduleCard(_schedules[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    final mediaTitle = _getMediaTitle(schedule.mediaId);
    final daysStr = schedule.daysOfWeek
        .map((d) => d < _dayNames.length ? _dayNames[d] : '?')
        .join(', ');

    return Card(
      color: const Color(AppConstants.surfaceColor),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: schedule.isActive
                ? const Color(AppConstants.primaryColor).withValues(alpha: 0.2)
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.schedule,
            color: schedule.isActive ? const Color(AppConstants.accentColor) : Colors.grey,
          ),
        ),
        title: Text(
          schedule.name ?? mediaTitle,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${schedule.startTime} - ${schedule.endTime}',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            Text(
              '$daysStr • Media: $mediaTitle',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: schedule.isActive,
              onChanged: (_) async {
                await _service.toggleSchedule(
                    schedule.id, !schedule.isActive);
                _fetchData();
              },
              activeThumbColor: Colors.green,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteSchedule(schedule),
            ),
          ],
        ),
      ),
    );
  }
}
