import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroScreen extends StatelessWidget {
  final VoidCallback onFinish;

  const IntroScreen({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Welcome to ShadowDocs",
          body: "A secure E2EE document sync app with a strong focus on privacy and anonymity.",
          image: Center(child: Icon(Icons.security, size: 100, color: Colors.blue)),
        ),
        PageViewModel(
          title: "Collaborate Seamlessly",
          body: "Create or join shadows to collaborate on documents in real-time.",
          image: Center(child: Icon(Icons.group, size: 100, color: Colors.green)),
        ),
        PageViewModel(
          title: "Your Privacy Matters",
          body: "No accounts, no databases. Your data stays with you.",
          image: Center(child: Icon(Icons.lock, size: 100, color: Colors.red)),
        ),
        PageViewModel(
          title: "Peer2Peer Connections",
          body: "ShadowDocs uses a secure Peer2Peer connection between shadows.",
          image: Center(child: Icon(Icons.construction, size: 100, color: Colors.deepPurple)),
        ),
        PageViewModel(
          title: "Early Development Phase",
          body: "Please note that this app is still in early development stages.",
          image: Center(child: Icon(Icons.construction, size: 100, color: Colors.orange)),
        ),
      ],
      onDone: onFinish,
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      back: const Icon(Icons.arrow_back),
      showBackButton: false,  // Changed to false
      done: const Text("Get Started", style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
