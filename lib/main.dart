import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:wedding_online/services/storage_service.dart';
import 'package:wedding_online/view/home_view.dart';
import 'package:wedding_online/view/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await StorageService().getToken();
  runApp(MyApp(initialRoute: token != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wedding Online',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // builder: (context, widget) => ResponsiveBreakpoints.builder(
      //   child: BouncingScrollWrapper.builder(context, widget!),
      //   breakpoints: [
      //     Breakpoint(start: 0, end: 480, name: MOBILE),
      //     Breakpoint(start: 481, end: 800, name: TABLET),
      //     Breakpoint(start: 801, end: 1024, name: DESKTOP),
      //     Breakpoint(start: 1025, end: double.infinity, name: 'XL'),
      //   ],
      // ),
      builder: (context, widget) => ResponsiveBreakpoints.builder(
        child: Center(
          child: SizedBox(
            width: 414, // Lebar maksimum layout (seperti mobile iPhone 12)
            child: widget!,
          ),
        ),
        breakpoints: [
          Breakpoint(start: 0, end: 480, name: MOBILE),
          Breakpoint(start: 481, end: 1024, name: TABLET),
          Breakpoint(start: 1025, end: double.infinity, name: DESKTOP),
        ],
      ),
      initialRoute: initialRoute,
      routes: {'/login': (_) => LoginView(), '/home': (_) => HomeView()},
    );
  }
}
