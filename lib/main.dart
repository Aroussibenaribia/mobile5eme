import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/data/homefix_repository.dart';
import 'services/homefix_data.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/screens/main_shell_screen.dart';
import 'services/auth_service.dart';
import 'services/professional_service.dart';
import 'features/forum/providers/forum_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set clean system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const HomeFixApp());
}

class HomeFixApp extends StatelessWidget {
  const HomeFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeFixRepository()),
        ChangeNotifierProvider(
            create: (ctx) => HomeFixData(ctx.read<HomeFixRepository>())),
        ChangeNotifierProvider(
            create: (ctx) => AuthService(
                repository: ctx.read<HomeFixRepository>(),
                restoreSession: true)),
        ChangeNotifierProvider(
            create: (ctx) =>
                ProfessionalService(repository: ctx.read<HomeFixRepository>())),
        ChangeNotifierProvider(create: (_) => ForumProvider()),
      ],
      child: MaterialApp(
        title: 'HomeFix — Services à Domicile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainShellScreen(),
      ),
    );
  }
}
