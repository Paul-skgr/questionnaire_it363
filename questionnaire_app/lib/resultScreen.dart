import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final int correctAnswersCount;
  final int totalQuestions;

  const ResultPage(
      {super.key,
      required this.correctAnswersCount,
      required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    double scorePercentage = (correctAnswersCount / totalQuestions) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Quiz terminé !',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text(
              'Vous avez répondu correctement à $correctAnswersCount / $totalQuestions questions.',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              'Votre score est de ${scorePercentage.toStringAsFixed(2)}%.',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Recommencer le Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}