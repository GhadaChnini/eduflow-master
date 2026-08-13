import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../screens/auth/landing_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/teacher_login_screen.dart';
import '../screens/auth/apply_teacher_screen.dart';
import '../screens/student/dashboard_screen.dart';
import '../screens/student/browse_screen.dart';
import '../screens/student/unit_detail_screen.dart';
import '../screens/student/leaderboard_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/notifications_screen.dart';
import '../screens/student/forum_screen.dart';
import '../screens/student/search_screen.dart';
import '../screens/student/sessions_screen.dart' as student_sessions;
import '../screens/student/progress_screen.dart';
import '../screens/student/leaderboard_screen.dart';
import '../screens/student/achievements_screen.dart';
import '../screens/student/games_screen.dart';
import '../screens/student/payment_screen.dart';
import '../screens/teacher/bank_details_screen.dart';
import '../screens/student/quiz_screen.dart' as student_quiz_screen;
import '../screens/student/settings_screen.dart' as student_settings;
import '../screens/student/progress_screen.dart';
import '../screens/student/achievements_screen.dart';
import '../screens/student/games_screen.dart';
import '../screens/student/messages_screen.dart';
import '../screens/teacher/dashboard_screen.dart';
import '../screens/teacher/units_screen.dart';
import '../screens/teacher/teacher_unit_detail_screen.dart';
import '../screens/teacher/create_unit_screen.dart';
import '../screens/teacher/sessions_screen.dart' as teacher_sessions;
import '../screens/teacher/students_screen.dart';
import '../screens/teacher/announcements_screen.dart';
import '../screens/teacher/games_screen.dart';
import '../screens/teacher/earnings_screen.dart';
import '../screens/teacher/profile_screen.dart';
import '../screens/teacher/notifications_screen.dart';
import '../screens/teacher/analytics_screen.dart';
import '../screens/teacher/quiz_screen.dart';
import '../screens/teacher/settings_screen.dart' as teacher_settings_screen;
import '../screens/games/memory_game_screen.dart';
import '../screens/games/word_scramble_screen.dart';
import '../screens/games/math_challenge_screen.dart';
import '../screens/games/spin_wheel_screen.dart';
import '../screens/games/picture_match_screen.dart';
import '../screens/games/catch_answer_screen.dart';
import '../screens/games/webview_game_screen.dart';
import '../screens/parent/parental_controls_screen.dart';
import '../screens/parent/parental_controls_screen.dart';
import '../widgets/common/main_scaffold.dart';
import '../widgets/common/teacher_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      if (isAuthRoute) return null;

      final supabase = ref.read(supabaseProvider);
      final isLoggedIn = supabase.auth.currentUser != null;
      final isLanding = state.matchedLocation == '/';

      if (!isLoggedIn && !isLanding) {
        return '/';
      }

      // Block navigation when locked - redirect to locked location
      final isLocked = ref.read(isLockedProvider);
      if (isLocked) {
        final lockedLocation = ref.read(lockedLocationProvider);
        if (lockedLocation.isNotEmpty && state.matchedLocation != lockedLocation) {
          return lockedLocation;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const LandingScreen()),
      GoRoute(path: '/auth/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/auth/teacher-login', builder: (c, s) => const TeacherLoginScreen()),
      GoRoute(path: '/auth/apply-teacher', builder: (c, s) => const ApplyTeacherScreen()),
      GoRoute(path: '/parental-controls', builder: (c, s) => const ParentalControlsScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const StudentDashboardScreen()),
          GoRoute(path: '/browse', builder: (c, s) => const BrowseScreen()),
          GoRoute(path: '/unit/:id', builder: (c, s) => UnitDetailScreen(unitId: s.pathParameters['id']!)),
          GoRoute(path: '/leaderboard', builder: (c, s) => const LeaderboardScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const StudentProfileScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const student_settings.StudentSettingsScreen()),
          GoRoute(path: '/forum', builder: (c, s) => const ForumScreen()),
          GoRoute(path: '/notifications', builder: (c, s) => const StudentNotificationsScreen()),
          GoRoute(path: '/progress', builder: (c, s) => const ProgressScreen()),
          GoRoute(path: '/leaderboard', builder: (c, s) => const LeaderboardScreen()),
          GoRoute(path: '/achievements', builder: (c, s) => const AchievementsScreen()),
          GoRoute(path: '/games', builder: (c, s) => const StudentGamesScreen()),
          GoRoute(path: '/achievements', builder: (c, s) => const AchievementsScreen()),
          GoRoute(path: '/games', builder: (c, s) => const StudentGamesScreen()),
          GoRoute(path: '/sessions', builder: (c, s) => student_sessions.StudentSessionsScreen()),
        ],
      ),
      GoRoute(path: '/messages', builder: (c, s) => const MessagesScreen()),
      ShellRoute(
        builder: (context, state, child) => TeacherScaffold(child: child),
        routes: [
          GoRoute(path: '/teacher', builder: (c, s) => const TeacherDashboardScreen()),
          GoRoute(path: '/teacher/units', builder: (c, s) => const TeacherUnitsScreen(),
            routes: [
              GoRoute(path: 'create', builder: (c, s) => const CreateUnitScreen()),
              GoRoute(path: ':id', builder: (c, s) => TeacherUnitDetailScreen(unitId: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: '/teacher/sessions', builder: (c, s) => teacher_sessions.TeacherSessionsScreen()),
          GoRoute(path: '/teacher/students', builder: (c, s) => TeacherStudentsScreen()),
          GoRoute(path: '/teacher/announcements', builder: (c, s) => const AnnouncementsScreen()),
          GoRoute(path: '/teacher/forum', builder: (c, s) => const ForumScreen()),
          GoRoute(path: '/teacher/earnings', builder: (c, s) => const EarningsScreen()),
          GoRoute(path: '/teacher/profile', builder: (c, s) => const TeacherProfileScreen()),
          GoRoute(path: '/teacher/notifications', builder: (c, s) => const TeacherNotificationsScreen()),
          GoRoute(path: '/teacher/analytics', builder: (c, s) => const AnalyticsScreen()),
          GoRoute(path: '/teacher/quiz', builder: (c, s) => const TeacherQuizScreen()),
          GoRoute(path: '/teacher/settings', builder: (c, s) => const teacher_settings_screen.TeacherSettingsScreen()),
          GoRoute(path: '/teacher/earnings', builder: (c, s) => const EarningsScreen()),
          GoRoute(path: '/teacher/bank', builder: (c, s) => const TeacherBankDetailsScreen()),
        ],
      ),
      GoRoute(path: '/game/memory', builder: (c, s) => const MemoryGameScreen()),
      GoRoute(path: '/game/word-scramble', builder: (c, s) => const WordScrambleScreen()),
      GoRoute(path: '/game/math-challenge', builder: (c, s) => const MathChallengeScreen()),
      GoRoute(path: '/game/spin-wheel', builder: (c, s) => const SpinWheelScreen()),
      GoRoute(path: '/game/picture-match', builder: (c, s) => const PictureMatchScreen()),
      GoRoute(path: '/game/catch-answer', builder: (c, s) => const CatchAnswerScreen()),
      GoRoute(
        path: '/game/webview',
        builder: (c, s) => WebViewGameScreen(
          url: s.uri.queryParameters['url'] ?? '',
          title: s.uri.queryParameters['title'] ?? 'Game',
        ),
      ),
    ],
  );
});