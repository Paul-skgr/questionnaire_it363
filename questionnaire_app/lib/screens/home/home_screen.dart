import 'package:flutter/material.dart';
import 'package:questionnaire_app/quiz_page.dart';
import 'package:questionnaire_app/services/authentication.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  final AuthenticationService _auth = AuthenticationService();

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déconnexion')),
      );
    }
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
    );
  }
}
