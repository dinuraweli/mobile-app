import 'package:flutter/material.dart';

class SalliBotScreen extends StatelessWidget {
  const SalliBotScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SalliBot AI'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy, size: 100, color: Colors.teal), const SizedBox(height: 24), const Text('SalliBot is Offline', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 32.0), child: Text('Your localized conversational AI is coming soon!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))), const SizedBox(height: 32),
            ElevatedButton(onPressed: () {}, child: const Text('Join Waitlist'))
          ],
        ),
      ),
    );
  }
}
