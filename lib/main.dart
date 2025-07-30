import 'package:flutter/material.dart';
import 'package:wedding_online/services/storage_service.dart';
import 'package:wedding_online/view/home_view.dart';
import 'package:wedding_online/view/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await StorageService().getToken();
  runApp(MyApp(initialRoute: token != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: initialRoute,
      routes: {'/login': (_) => LoginView(), '/home': (_) => HomeView()},
      home: LoginView(),
    );
  }
}
