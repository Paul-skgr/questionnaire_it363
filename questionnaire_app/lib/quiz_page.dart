import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'resultScreen.dart';

class QuizPage extends StatefulWidget {
  final List<String> selectedCategories;

  const QuizPage({
    Key? key,
    required this.selectedCategories,
  }) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> quizQuestions = [];
  int _currentQuestionIndex = 0;
  String _selectedAnswer = '';
  int _correctAnswersCount = 0;
  bool _isLoading = true; // Indique si les données sont en cours de chargement

  @override
  void initState() {
    super.initState();
    _loadQuestionsFromFirestore();
  }

  /// Charger les questions depuis Firestore pour les catégories sélectionnées
  Future<void> _loadQuestionsFromFirestore() async {
    try {
      List<Map<String, dynamic>> loadedQuestions = [];

      for (String category in widget.selectedCategories) {
        QuerySnapshot snapshot =
            await _firestore.collection(category).get(); // Récupère les docs
        for (var doc in snapshot.docs) {
          loadedQuestions.add(doc.data() as Map<String, dynamic>);
        }
      }

      // Mélanger les questions pour varier leur ordre
      loadedQuestions.shuffle(Random());

      setState(() {
        quizQuestions = loadedQuestions;
        _isLoading = false; // Les données sont prêtes
      });
    } catch (e) {
      print("Erreur lors du chargement des questions : $e");
    }
  }

  Widget _printQuestionAnswers(
      Map<String, dynamic> currentQuestion, List<String> options) {
    switch (currentQuestion["type"]) {
      case "single-choice":
        return Column(
          children: options.map((option) {
            final isCorrectAnswer = option == currentQuestion['correct_answer'];
            final isSelectedCorrect =
                _selectedAnswer == 'correct' && isCorrectAnswer;
            final isSelectedIncorrect =
                _selectedAnswer == 'incorrect' && isCorrectAnswer;
            final isIncorrectOption =
                _selectedAnswer == 'incorrect' && !isCorrectAnswer;

            Color backgroundColor = isSelectedCorrect || isSelectedIncorrect
                ? Colors.green
                : isIncorrectOption
                    ? Colors.red
                    : Colors.blue;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  disabledBackgroundColor: backgroundColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _selectedAnswer.isEmpty
                    ? () {
                        _checkAnswer(option, currentQuestion['correct_answer']);
                      }
                    : null,
                child: Text(option, style: const TextStyle(fontSize: 18)),
              ),
            );
          }).toList(),
        );
      case "images":
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: options.map((option) {
            final isCorrectAnswer = option == currentQuestion['correct_answer'];
            final isSelectedCorrect =
                _selectedAnswer == 'correct' && isCorrectAnswer;
            final isSelectedIncorrect =
                _selectedAnswer == 'incorrect' && isCorrectAnswer;
            final isIncorrectOption =
                _selectedAnswer == 'incorrect' && !isCorrectAnswer;

            Color backgroundColor = isSelectedCorrect || isSelectedIncorrect
                ? Colors.green
                : isIncorrectOption
                    ? Colors.red
                    : Colors.blue;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  disabledBackgroundColor: backgroundColor,
                  minimumSize: const Size(100, 100),
                  maximumSize: const Size(150, 150),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _selectedAnswer.isEmpty
                    ? () {
                        _checkAnswer(option, currentQuestion['correct_answer']);
                      }
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      '../assets/images/${currentQuestion["images"][options.indexOf(option)]}',
                      width: 80,
                      height: 80,
                    ),
                    Text(option, style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      default:
        throw Exception("Type de question inconnu");
    }
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < quizQuestions.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswer = ''; // Réinitialiser la sélection de la réponse
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ResultPage(
                  correctAnswersCount: _correctAnswersCount,
                  totalQuestions: quizQuestions.length)),
        );
      }
    });
  }

  void _checkAnswer(String selectedOption, String correctAnswer) {
    setState(() {
      if (selectedOption == correctAnswer) {
        _correctAnswersCount++;
      }
      _selectedAnswer =
          selectedOption == correctAnswer ? 'correct' : 'incorrect';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: Text(
            'Aucune question disponible pour les catégories sélectionnées.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
            Text(
              'Catégorie: ${currentQuestion['category']}',
              style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              currentQuestion['question'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: _printQuestionAnswers(currentQuestion, options),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _nextQuestion,
              child: Text(
                _currentQuestionIndex == quizQuestions.length - 1
                    ? 'Voir les Résultats'
                    : 'Suivant',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
