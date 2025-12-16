import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  assert(
    supabaseUrl.isNotEmpty,
    'SUPABASE_URL is required. Pass it via --dart-define.',
  );
  assert(
    supabaseAnonKey.isNotEmpty,
    'SUPABASE_ANON_KEY is required. Pass it via --dart-define.',
  );

  await initializeSupabase(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: App()));
}
