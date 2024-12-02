import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'resultScreen.dart';

class QuizPage extends StatefulWidget {
  final List<String> selectedCategories;

  const QuizPage({super.key, required this.selectedCategories});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Map<String, List<Map<String, dynamic>>> questions;
  late List<Map<String, dynamic>> quizQuestions;
  late List<Map<String, dynamic>> higherDifficultyQuestions;
  late Map<String, dynamic> storedQuestion;
  int _currentQuestionIndex = 0;
  int _difficulty = 0;
  String _selectedAnswer = '';
  int _correctAnswersCount = 0; // Variable pour compter les bonnes réponses
  bool _isDiffChecked = false;
  bool _isAlreadyExecuted = false;

  // Fonction pour charger les questions depuis le fichier JSON
  Future<void> _loadQuestions() async {
    final String response =
        await rootBundle.loadString('assets/questions.json');
    final Map<String, dynamic> data = json.decode(response);

    setState(() {
      questions = data.map((key, value) {
        return MapEntry(
            key, List<Map<String, dynamic>>.from(value.map((item) => item)));
      });

      // Filtrer les questions par catégorie sélectionnée
      quizQuestions = [];
      higherDifficultyQuestions = [];
      for (String category in widget.selectedCategories) {
        quizQuestions.addAll(questions[category]
                ?.where((question) => question["difficulty"] == 0) ??
            []);
        higherDifficultyQuestions.addAll(questions[category]
                ?.where((question) => question["difficulty"] >= 1) ??
            []);
      }

      // Mélanger les questions de manière aléatoire
      quizQuestions.shuffle(Random());
    });
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions(); // Charger les questions au démarrage
  }

  Widget _printQuestionAnswers(
      Map<String, dynamic> currentQuestion, List<String> options) {
    // Afficher les réponses sous forme de boutons
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
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: options.map((option) {
              final isCorrectAnswer =
                  option == currentQuestion['correct_answer'];
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
                    minimumSize: const Size(100, 100), // Make the button square
                    maximumSize: const Size(150, 150),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _selectedAnswer.isEmpty
                      ? () {
                          _checkAnswer(
                              option, currentQuestion['correct_answer']);
                        }
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        '${currentQuestion["images"][options.indexOf(option)]}',
                        width: 80,
                        height: 80,
                      ),
                      Text(option, style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
        _isDiffChecked = false;
      } else {
        // Afficher la page de résultats avec le score final
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
        _correctAnswersCount++; // Incrémenter le nombre de bonnes réponses
        _difficulty++;
        _difficulty++;
        debugPrint('Difficulty: $_difficulty');
      }
      _selectedAnswer =
          selectedOption == correctAnswer ? 'correct' : 'incorrect';
    });
  }

  Map<String, dynamic> _getCurrentQuestion() {
    Map<String, dynamic> currentQuestion;

    // Checking for higher difficulty questions...
    if (!_isDiffChecked) {
      currentQuestion = quizQuestions[_currentQuestionIndex];
      int currentID = currentQuestion['id'];
      // Chercher les questions de higherDifficultyQuestions avec le même ID que currentID
      List<Map<String, dynamic>> matchingQuestions = higherDifficultyQuestions
          .where((question) => question['id'] == currentID)
          .toList();

      // Filtrer les questions dont la difficulté est inférieure à _difficulty
      List<Map<String, dynamic>> filteredQuestions = matchingQuestions
          .where((question) => question['difficulty'] < _difficulty)
          .toList();

      // Si des questions correspondent, prendre celle avec la difficulté la plus élevée
      if (filteredQuestions.isNotEmpty) {
        filteredQuestions
            .sort((a, b) => b['difficulty'].compareTo(a['difficulty']));
        currentQuestion = filteredQuestions.first;
      }
      storedQuestion = currentQuestion;
      _isDiffChecked = true;
      return currentQuestion;
    } else {
      return storedQuestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
            child:
                CircularProgressIndicator()), // Afficher un chargement si les questions ne sont pas encore chargées
      );
    }

    Map<String, dynamic> currentQuestion = _getCurrentQuestion();

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
              style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Afficher la question
            Text(
              currentQuestion['question'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: _printQuestionAnswers(currentQuestion, options),
                  ),
                ),
              ),
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
