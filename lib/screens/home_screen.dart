import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/media_provider.dart';
import '../services/pip_service.dart';
import '../services/intent_service.dart';
import '../widgets/ad_display_widget.dart';
import '../widgets/marquee_widget.dart';
import '../widgets/clock_widget.dart';
import '../widgets/tv_focus_widgets.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';
import 'admin_panel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _showControls = false;
  bool _isPipSupported = false;
  final FocusNode _mainFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPipSupport();

    // Initialize media provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaProvider>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mainFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkPipSupport() async {
    final supported = await PipService.instance.isPipSupported();
    if (mounted) {
      setState(() => _isPipSupported = supported);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<MediaProvider>();
    if (state == AppLifecycleState.resumed) {
      provider.setPipMode(false);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _launchCliniqTv() async {
    final provider = context.read<MediaProvider>();
    final packageName = provider.cliniqTvPackage;

    if (_isPipSupported) {
      final entered = await PipService.instance.enterPip();
      if (entered) {
        provider.setPipMode(true);
      }
    }

    final launched = await IntentService.instance.launchCliniqTv(packageName);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'CliniqTV app not found. Please install it first.',
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: Consumer<MediaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingScreen();
          }

          if (provider.error != null) {
            return _buildErrorScreen(provider.error!);
          }

          if (provider.mediaItems.isEmpty) {
            return _buildNoMediaScreen();
          }

          return KeyboardListener(
            focusNode: _mainFocusNode,
            autofocus: true,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  _toggleControls();
                } else if (event.logicalKey == LogicalKeyboardKey.goBack ||
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  if (_showControls) {
                    setState(() => _showControls = false);
                  }
                }
              }
            },
            child: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  // Main ad display
                  _buildMainDisplay(provider),

                  // Top bar with logo and clock
                  _buildTopBar(provider),

                  // Bottom marquee
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: MarqueeWidget(text: provider.marqueeText),
                  ),

                  // Media indicator dots (only in single mode)
                  if (!provider.isPipMode && provider.displayMode == 'single')
                    Positioned(
                      bottom: 56,
                      left: 0,
                      right: 0,
                      child: _buildMediaIndicator(provider),
                    ),

                  // Layout mode badge
                  if (provider.displayMode != 'single')
                    Positioned(
                      bottom: 56,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          provider.displayMode == 'grid2'
                              ? '2-Split'
                              : '4-Grid',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),

                  // Controls overlay
                  if (_showControls) _buildControlsOverlay(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build the main display — single or grid layout
  Widget _buildMainDisplay(MediaProvider provider) {
    switch (provider.displayMode) {
      case 'grid2':
        return _buildGrid2(provider);
      case 'grid4':
        return _buildGrid4(provider);
      default:
        return _buildSingleDisplay(provider);
    }
  }

  Widget _buildSingleDisplay(MediaProvider provider) {
    final currentMedia = provider.currentMedia;
    if (currentMedia == null) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: Duration(milliseconds: AppConstants.adTransitionDurationMs),
      child: AdDisplayWidget(
        key: ValueKey('single_${currentMedia.id}'),
        mediaItem: currentMedia,
        onComplete: () => provider.onVideoComplete(),
        isPipMode: provider.isPipMode,
      ),
    );
  }

  Widget _buildGrid2(MediaProvider provider) {
    final items = provider.gridMediaItems;
    return Row(
      children: [
        for (int i = 0; i < 2; i++)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: i == 0
                      ? const BorderSide(color: Colors.black, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: i < items.length
                  ? AdDisplayWidget(
                      key: ValueKey('grid2_${i}_${items[i].id}'),
                      mediaItem: items[i],
                      onComplete: () => provider.nextMedia(),
                      isPipMode: false,
                    )
                  : Container(color: Colors.black),
            ),
          ),
      ],
    );
  }

  Widget _buildGrid4(MediaProvider provider) {
    final items = provider.gridMediaItems;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              for (int i = 0; i < 2; i++)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: i == 0
                            ? const BorderSide(
                                color: Colors.black, width: 2)
                            : BorderSide.none,
                        bottom:
                            const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: i < items.length
                        ? AdDisplayWidget(
                            key: ValueKey('grid4_${i}_${items[i].id}'),
                            mediaItem: items[i],
                            onComplete: () => provider.nextMedia(),
                            isPipMode: false,
                          )
                        : Container(color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              for (int i = 2; i < 4; i++)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: i == 2
                            ? const BorderSide(
                                color: Colors.black, width: 2)
                            : BorderSide.none,
                      ),
                    ),
                    child: i < items.length
                        ? AdDisplayWidget(
                            key: ValueKey('grid4_${i}_${items[i].id}'),
                            mediaItem: items[i],
                            onComplete: () => provider.nextMedia(),
                            isPipMode: false,
                          )
                        : Container(color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(MediaProvider provider) {
    if (provider.isPipMode) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo / App name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CliniqTV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Hospital Display System',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Clock
            const ClockWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaIndicator(MediaProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        provider.mediaItems.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == provider.currentIndex ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == provider.currentIndex
                ? const Color(AppConstants.accentColor)
                : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(MediaProvider provider) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TvFocusButton(
                      autofocus: true,
                      label: 'Previous',
                      icon: Icons.skip_previous,
                      onPressed: () => provider.previousMedia(),
                      width: 160,
                    ),
                    const SizedBox(width: 16),
                    TvFocusButton(
                      label: 'Next',
                      icon: Icons.skip_next,
                      onPressed: () => provider.nextMedia(),
                      width: 160,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Layout toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLayoutButton(provider, 'single', 'Single', Icons.crop_landscape),
                    const SizedBox(width: 12),
                    _buildLayoutButton(provider, 'grid2', '2-Split', Icons.vertical_split),
                    const SizedBox(width: 12),
                    _buildLayoutButton(provider, 'grid4', '4-Grid', Icons.grid_view),
                  ],
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPipSupported)
                      TvFocusButton(
                        label: 'Launch Queue App',
                        icon: Icons.picture_in_picture,
                        onPressed: _launchCliniqTv,
                        width: 240,
                        backgroundColor: const Color(AppConstants.primaryColor),
                      ),
                    if (_isPipSupported) const SizedBox(width: 16),
                    TvFocusButton(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      onPressed: () => provider.refresh(),
                      width: 160,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TvFocusButton(
                      label: 'Settings',
                      icon: Icons.settings,
                      onPressed: () {
                        setState(() => _showControls = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      width: 160,
                    ),
                    const SizedBox(width: 16),
                    TvFocusButton(
                      label: 'Admin Panel',
                      icon: Icons.admin_panel_settings,
                      onPressed: () {
                        setState(() => _showControls = false);
                        final prov = context.read<MediaProvider>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminPanelScreen(),
                          ),
                        ).then((_) {
                          prov.refresh();
                        });
                      },
                      width: 180,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Exit button
                TvFocusButton(
                  label: 'Exit App',
                  icon: Icons.power_settings_new,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(AppConstants.surfaceColor),
                        title: const Text('Exit App',
                            style: TextStyle(color: Colors.white)),
                        content: const Text(
                            'Are you sure you want to exit CliniqTV?',
                            style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              SystemNavigator.pop();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Exit'),
                          ),
                        ],
                      ),
                    );
                  },
                  width: 180,
                  backgroundColor: Colors.red[800],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Press BACK to close controls',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutButton(
      MediaProvider provider, String mode, String label, IconData icon) {
    final isActive = provider.displayMode == mode;
    return GestureDetector(
      onTap: () => provider.setDisplayMode(mode),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter)) {
            provider.setDisplayMode(mode);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(AppConstants.primaryColor)
                    : focused
                        ? const Color(AppConstants.accentColor)
                        : const Color(AppConstants.surfaceColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: focused
                      ? Colors.white
                      : isActive
                          ? const Color(AppConstants.primaryColor)
                          : Colors.grey[700]!,
                  width: focused ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(label,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(AppConstants.accentColor),
            strokeWidth: 4,
          ),
          SizedBox(height: 24),
          Text(
            'Loading CliniqTV...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Connecting to server',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Connection Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TvFocusButton(
            autofocus: true,
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: () {
              context.read<MediaProvider>().initialize();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoMediaScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.tv_off,
            color: Colors.white38,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'No Media Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload media through the admin panel\nto start displaying ads',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TvFocusButton(
                autofocus: true,
                label: 'Open Admin Panel',
                icon: Icons.admin_panel_settings,
                onPressed: () {
                  final provider = context.read<MediaProvider>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminPanelScreen(),
                    ),
                  ).then((_) {
                    // Refresh media when returning from admin
                    provider.refresh();
                  });
                },
                width: 280,
                backgroundColor: const Color(AppConstants.primaryColor),
              ),
              const SizedBox(width: 24),
              TvFocusButton(
                label: 'Refresh',
                icon: Icons.refresh,
                onPressed: () {
                  context.read<MediaProvider>().refresh();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
