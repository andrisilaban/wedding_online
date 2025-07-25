import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:wedding_online/constants/styles.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  final List<String> galleryImages = [
    'assets/images/couple.jpg',
    'assets/images/gallery1.jpeg',
    'assets/images/gallery2.jpeg',
    'assets/images/gallery3.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900,
              Colors.purple.shade700,
              Colors.purple.shade400,
              Colors.purple.shade300,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              _buildWeddingInfoCard(),
              _buildWeddingInfoCard(),
              _buildWeddingInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeddingInfoCard() {
    return Stack(
      children: [
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.2,
          colors: const [
            Colors.orange,
            Colors.purple,
            Colors.blue,
            Colors.amber,
          ],
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: cardDecoration.copyWith(
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  decoration: circleImageDecoration.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/couple.jpg',
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "The Wedding of",
                  style: headerTextStyle.copyWith(fontFamily: 'Cormorant'),
                ),
                Text(
                  "Ahmad & Siti",
                  textAlign: TextAlign.center,
                  style: coupleNameTextStyle.copyWith(
                    fontSize: 38,
                    fontFamily: 'Cormorant',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.purple.shade200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.purple.shade300,
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.purple.shade200)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Cinta yang sejati bukanlah tentang menemukan seseorang yang sempurna "
                  "tetapi tentang melihat kesempurnaan dalam ketidaksempurnaan.",
                  textAlign: TextAlign.center,
                  style: italicTextStyle.copyWith(
                    fontSize: 16,
                    letterSpacing: 0.5,
                    wordSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
