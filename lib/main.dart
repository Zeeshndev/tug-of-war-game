import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart'; // Import the new service
import 'services/audio_service.dart';
import 'utils/theme.dart';
import 'utils/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  await StorageService.init();
  
  // MUST BOOT AD ENGINE BEFORE RUNNING APP
  await AdService().initialize(); 
  
  // Sync sound enabled state from saved profile immediately on startup
  AudioService().soundEnabled = StorageService.getProfile().soundOn;
  
  runApp(const ProviderScope(child: TugOfWarApp()));
}

// ── App Lifecycle Observer ───────────────────────────────────────────────────
class TugOfWarApp extends StatefulWidget {
  const TugOfWarApp({super.key});

  @override
  State<TugOfWarApp> createState() => _TugOfWarAppState();
}

class _TugOfWarAppState extends State<TugOfWarApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Start listening to app background/foreground changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Stop listening when app is completely destroyed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause music if the user minimizes the app, goes to home screen, or takes a call
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      AudioService().pauseTick();
    } 
    // Resume music only if they come back to the app
    else if (state == AppLifecycleState.resumed) {
      AudioService().resumeTick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BrainTug: Epic Math Battles',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      routerConfig: AppRouter.router,
    );
  }
}