import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/notes/add_note_screen.dart';
import '../../features/khata/khata_screen.dart';
import '../../features/khata/add_transaction_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/reminders/add_reminder_screen.dart';
import '../../features/todo/todo_screen.dart';
import '../../features/settings/settings_screen.dart';

// Simple key for the root navigator
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      // Only redirect on the splash route — splash handles own navigation
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Settings lives outside the shell (full-screen)
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/note/add',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddNoteScreen(existingNote: null, extras: extra);
        },
      ),
      GoRoute(
        path: '/note/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddNoteScreen(noteId: id, existingNote: null);
        },
      ),
      GoRoute(
        path: '/khata/add',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddTransactionScreen(extras: extra);
        },
      ),
      GoRoute(
        path: '/reminder/add',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddReminderScreen(extras: extra);
        },
      ),
      // Shell route for bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return HomeScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home/chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatScreen(),
            ),
          ),
          GoRoute(
            path: '/home/notes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotesScreen(),
            ),
          ),
          GoRoute(
            path: '/home/khata',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: KhataScreen(),
            ),
          ),
          GoRoute(
            path: '/home/todo',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TodoScreen(),
            ),
          ),
          GoRoute(
            path: '/home/reminders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RemindersScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFF7C6EF8)),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? ''),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home/chat'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
