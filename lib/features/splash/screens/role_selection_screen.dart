import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SOUTRALY',
                style: TextStyle(
                  fontSize: 48, // Agrandir le nom
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // Naviguer vers la page de connexion pour partenaire
                  Navigator.of(context).pushReplacementNamed('/sign-in');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Vous êtes partenaire'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Naviguer vers la page de connexion pour chauffeur
                  Navigator.of(context).pushReplacementNamed('/sign-in');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Vous êtes chauffeur'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Naviguer vers la page de connexion pour livreur
                  Navigator.of(context).pushReplacementNamed('/sign-in');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Vous êtes livreur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
