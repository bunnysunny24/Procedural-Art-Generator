import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'features/canvas/canvas_screen.dart';
import 'features/project_management/project_list_screen.dart';

class ProceduralArtGeneratorApp extends ConsumerWidget {
  const ProceduralArtGeneratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Procedural Art Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTextStyles.textTheme,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.appBarForeground,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: AppTextStyles.darkTextTheme,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.appBarBackgroundDark,
          foregroundColor: AppColors.appBarForegroundDark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const ProjectListScreen(),
      routes: {
        '/canvas': (context) => const CanvasScreen(),
        '/projects': (context) => const ProjectListScreen(),
      },
    );
  }
}