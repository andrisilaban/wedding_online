import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<String> galleryImages = [
    'assets/images/couple.jpg',
    'assets/images/gallery1.jpeg',
    'assets/images/gallery2.jpeg',
    'assets/images/gallery3.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Home')));
  }
}
