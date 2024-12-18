import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoricScreen extends StatefulWidget {
  const HistoricScreen({super.key});

  @override
  _HistoricScreenState createState() => _HistoricScreenState();
}

class _HistoricScreenState extends State<HistoricScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> _getUserQuizHistory() {
    User? user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('quiz_results')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Scores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour à la page précédente',
          onPressed: () {
              Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Retour à l\'accueil',
            onPressed: () {
              Navigator.of(context).pushNamed('/home');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserQuizHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement des données.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Aucun score enregistré pour l\'instant.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final quizResults = snapshot.data!.docs;

          return ListView.builder(
            itemCount: quizResults.length,
            itemBuilder: (context, index) {
              final result = quizResults[index];
              final score = result['score'] ?? 0;
              final totalQuestions = result['totalQuestions'] ?? 0;
              final timestamp = (result['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(
                    Icons.score,
                    color: Colors.blue,
                    size: 40,
                  ),
                  title: Text(
                    'Score : $score / $totalQuestions',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    timestamp != null
                        ? 'Date : ${timestamp.toLocal()}'
                        : 'Date : Inconnue',
                  ),
                  trailing: Text(
                    '${((score / totalQuestions) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}