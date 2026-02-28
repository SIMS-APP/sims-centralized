import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/media_provider.dart';
import '../widgets/tv_focus_widgets.dart';
import '../utils/constants.dart';
import 'admin_panel_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.tvSafeAreaPadding),
          child: Consumer<MediaProvider>(
            builder: (context, provider, _) {
              return FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        TvFocusButton(
                          autofocus: true,
                          label: 'Back',
                          icon: Icons.arrow_back,
                          onPressed: () => Navigator.pop(context),
                          width: 140,
                          height: 48,
                        ),
                        const SizedBox(width: 24),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Settings content
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - App Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('App Information'),
                                const SizedBox(height: 16),
                                _buildInfoCard(
                                  'Application',
                                  'CliniqTV Hospital Display System',
                                  Icons.tv,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  'Version',
                                  '1.0.0',
                                  Icons.info_outline,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  'Total Media',
                                  '${provider.mediaItems.length} items',
                                  Icons.perm_media,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  'Current Media',
                                  provider.currentMedia?.title ?? 'None',
                                  Icons.play_circle_outline,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  'Ad Rotation',
                                  '${provider.adRotationInterval} seconds',
                                  Icons.timer,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),

                          // Right column - Connection & Actions
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Server Configuration'),
                                const SizedBox(height: 16),
                                _buildInfoCard(
                                  'Supabase',
                                  AppConstants.supabaseUrl,
                                  Icons.cloud,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  'Queue App Package',
                                  provider.cliniqTvPackage,
                                  Icons.apps,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  'Marquee Text',
                                  provider.marqueeText,
                                  Icons.text_fields,
                                ),
                                const SizedBox(height: 32),
                                _buildSectionTitle('Actions'),
                                const SizedBox(height: 16),
                                TvFocusButton(
                                  label: 'Refresh Media',
                                  icon: Icons.refresh,
                                  onPressed: () async {
                                    await provider.refresh();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Media refreshed!'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  width: 220,
                                ),
                                const SizedBox(height: 16),
                                TvFocusButton(
                                  label: 'Admin Panel',
                                  icon: Icons.admin_panel_settings,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AdminPanelScreen(),
                                      ),
                                    );
                                  },
                                  width: 220,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(AppConstants.accentColor),
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.surfaceColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white60, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
