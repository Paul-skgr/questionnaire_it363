import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionnaire_app/quiz_page.dart';
import 'package:questionnaire_app/services/authentication.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  final AuthenticationService _auth = AuthenticationService();

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, bool> categories = {
    'Histoire': false,
    'Sport': false,
    'Sciences': false,
    'Loisirs': false,
  };

  Map<String, Color> categoryColors = {
    'Histoire': Colors.blue,
    'Sport': Colors.orange,
    'Sciences': Colors.green,
    'Loisirs': const Color.fromARGB(255, 235, 13, 13),
  };

  String _feedbackComment = "";

  void _startQuiz() {
    List<String> selectedCategories = categories.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(selectedCategories: selectedCategories),
      ),
    );
  }

  void _logout() async {
    try {
      await widget._auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déconnexion réussie')),
      );
      Navigator.of(context).pushReplacementNamed('/authenticate');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déconnexion')),
      );
    }
  }

  void _submitFeedbackToFirestore(String feedback) async {
    try {
      final currentUser = widget._auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('feedback').add({
          'userId': currentUser.uid,
          'feedback': feedback,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci pour votre feedback !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez être connecté pour envoyer un feedback')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi du feedback')),
      );
    }
  }
  void _submitFeedback() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Feedback'),
          content: SizedBox(
            height: 150,
            child: TextField(
              maxLines: null,
              keyboardType: TextInputType.multiline,
              onChanged: (value) {
                _feedbackComment = value;
              },
              decoration:
                  const InputDecoration(hintText: "Entrez votre feedback ici"),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_feedbackComment.isNotEmpty) {
                  _submitFeedbackToFirestore(_feedbackComment);
                  setState(() {
                    _feedbackComment = ""; // Reset feedback field after submission
                  });
                }
              },
              child: const Text('Soumettre'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz App'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Sélectionnez les catégories pour le quiz',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 300,
                  child: Column(
                    children: categories.keys.map((category) {
                      return CheckboxListTile(
                        title: Text(
                          category,
                          style: TextStyle(
                            color: categoryColors[category],
                          ),
                        ),
                        value: categories[category],
                        onChanged: (bool? value) {
                          setState(() {
                            categories[category] = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startQuiz,
                  child: const Text('Commencer le quiz'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton(
          tooltip: 'Feedback',
          onPressed: _submitFeedback,
          child: const Icon(Icons.favorite),
        ),
      ),
    );
  }
}