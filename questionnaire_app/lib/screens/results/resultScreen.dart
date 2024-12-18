import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultPage extends StatelessWidget {
  final double score;
  final double scoreMax;
  final int totalQuestions;
  final int correctAnswersCount;

  const ResultPage({
    super.key,
    required this.score,
    required this.scoreMax,
    required this.correctAnswersCount,
    required this.totalQuestions,
  });

  Future<void> _saveResult() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('quiz_results')
          .add({
        'score': score,
        'totalQuestions': totalQuestions,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _saveResult();

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
              'Votre score est de ${score.toStringAsFixed(2)} / ${scoreMax.toStringAsFixed(2)} (Les pertes et gains de points sont variables en fonction de la difficulté de chacune).',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Recommencer le Quiz'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/history');
              },
              child: const Text('Voir l’historique des scores'),
            ),
          ],
        ),
      ),
    );
  }
}
