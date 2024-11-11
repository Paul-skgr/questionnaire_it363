import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuizPage extends StatefulWidget {
  final List<String> selectedCategories;

  QuizPage({required this.selectedCategories});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Map<String, List<Map<String, dynamic>>> questions;
  late List<Map<String, dynamic>> quizQuestions;
  int _currentQuestionIndex = 0;
  String _selectedAnswer = '';
  int _correctAnswersCount = 0; // Variable pour compter les bonnes réponses

  // Fonction pour charger les questions depuis le fichier JSON
  Future<void> _loadQuestions() async {
    final String response = await rootBundle.loadString('assets/questions.json');
    final Map<String, dynamic> data = json.decode(response);

    setState(() {
      questions = data.map((key, value) {
        return MapEntry(key, List<Map<String, dynamic>>.from(value.map((item) => item)));
      });

      // Filtrer les questions par catégorie sélectionnée
      quizQuestions = [];
      for (String category in widget.selectedCategories) {
        quizQuestions.addAll(questions[category] ?? []);
      }

      // Mélanger les questions de manière aléatoire
      quizQuestions.shuffle(Random());
    });
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();  // Charger les questions au démarrage
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < quizQuestions.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswer = '';  // Réinitialiser la sélection de la réponse
      } else {
        // Afficher la page de résultats avec le score final
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResultPage(correctAnswersCount: _correctAnswersCount, totalQuestions: quizQuestions.length)),
        );
      }
    });
  }

  void _checkAnswer(String selectedOption, String correctAnswer) {
    setState(() {
      if (selectedOption == correctAnswer) {
        _correctAnswersCount++; // Incrémenter le nombre de bonnes réponses
      }
      _selectedAnswer = selectedOption == correctAnswer ? 'correct' : 'incorrect';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: Center(child: CircularProgressIndicator()),  // Afficher un chargement si les questions ne sont pas encore chargées
      );
    }

    // Récupérer la question courante
    Map<String, dynamic> currentQuestion = quizQuestions[_currentQuestionIndex];
    List<String> options = List<String>.from(currentQuestion['options']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentQuestionIndex + 1}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Afficher la catégorie de la question
            Text(
              'Catégorie: ${currentQuestion['category']}',
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // Afficher la question
            Text(
              currentQuestion['question'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            // Afficher les réponses sous forme de boutons
            Column(
              children: options.map((option) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAnswer == 'correct' && option == currentQuestion['correct_answer']
                          ? Colors.green
                          : _selectedAnswer == 'incorrect' && option != currentQuestion['correct_answer']
                              ? Colors.red
                              : Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      _checkAnswer(option, currentQuestion['correct_answer']);
                    },
                    child: Text(option, style: TextStyle(fontSize: 18)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _nextQuestion,
              child: Text(
                _currentQuestionIndex == quizQuestions.length - 1
                    ? 'Voir les Résultats'
                    : 'Suivant',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ResultPage extends StatelessWidget {
  final int correctAnswersCount;
  final int totalQuestions;

  // Constructeur pour recevoir les paramètres
  ResultPage({required this.correctAnswersCount, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    double scorePercentage = (correctAnswersCount / totalQuestions) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Quiz terminé !',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              'Vous avez répondu correctement à $correctAnswersCount / $totalQuestions questions.',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Votre score est de ${scorePercentage.toStringAsFixed(2)}%.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);  // Retour à la page d'accueil
              },
              child: Text('Recommencer le Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
