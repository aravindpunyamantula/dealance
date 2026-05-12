import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:striv/services/auth_provider.dart';
import 'package:striv/services/pitch_form_controller.dart';
import 'package:striv/screens/splash_screen.dart';
import 'package:striv/utils/app_palette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const DealanceApp(),
    ),
  );
}

class DealanceApp extends StatelessWidget {
  const DealanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PitchFormController()),
      ],
      child: MaterialApp(
        title: 'Dealance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        home: const SplashScreen(),
      ),
    );
  }
}
