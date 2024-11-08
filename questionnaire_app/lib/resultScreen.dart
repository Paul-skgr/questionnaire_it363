import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final VoidCallback onRestart; // Fonction pour redémarrer le quiz

  ResultScreen({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    double scorePercentage = (correctAnswers / totalQuestions) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats du Quiz'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Votre Score :',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.0),
              Text(
                '${correctAnswers} / ${totalQuestions}',
                style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              SizedBox(height: 20.0),
              Text(
                'Score en pourcentage : ${scorePercentage.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 20.0),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  onRestart(); // Appeler la fonction pour redémarrer le quiz
                  Navigator.pop(context); // Revenir à la première page du quiz
                },
                child: Text('Recommencer le quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
