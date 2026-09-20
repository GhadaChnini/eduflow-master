import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../services/language_service.dart';

class TeacherScaffold extends ConsumerWidget {
  final Widget child;
  const TeacherScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      {'icon': Icons.home_rounded, 'route': '/teacher', 'label': 'Home'},
      {'icon': Icons.menu_book_rounded, 'route': '/teacher/units', 'label': 'Units'},
      {'icon': Icons.forum_rounded, 'route': '/teacher/forum', 'label': 'Forum'},
      {'icon': Icons.people_rounded, 'route': '/teacher/students', 'label': 'Students'},
      {'icon': Icons.settings_rounded, 'route': '/teacher/settings', 'label': 'Settings'},
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1B4B) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: tabs.asMap().entries.map((entry) {
                    final tab = entry.value;
                    final route = tab['route'] as String;
                    final icon = tab['icon'] as IconData;
                    final label = tab['label'] as String;
                    final isActive = location == route || (route != '/teacher' && location.startsWith(route));

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => context.go(route),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: isActive ? 22 : 20,
                                color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                              ),
                              if (isActive) ...[
                                const SizedBox(height: 2),
                                Text(
                                  label,
                                  style: const TextStyle(fontSize: 9, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
        ),
      ),
    );
  }
}