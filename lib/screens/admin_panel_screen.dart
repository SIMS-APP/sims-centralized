import 'package:flutter/material.dart';
import 'admin_media_screen.dart';
import 'admin_schedules_screen.dart';
import 'admin_settings_screen.dart';
import '../utils/constants.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminMediaScreen(),
    AdminSchedulesScreen(),
    AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: const Text('CliniqTV Admin Panel'),
        backgroundColor: const Color(AppConstants.surfaceColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Side navigation rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            backgroundColor: const Color(AppConstants.surfaceColor),
            indicatorColor: const Color(AppConstants.primaryColor),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme: IconThemeData(color: Colors.grey[500]),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.tv, color: Colors.blue, size: 32),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.perm_media_outlined),
                selectedIcon: Icon(Icons.perm_media),
                label: Text('Media'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.schedule_outlined),
                selectedIcon: Icon(Icons.schedule),
                label: Text('Schedules'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF2D2D2D)),
          // Content area
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
