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
  int _currentQuestionIndex = 0;
  String _selectedAnswer = '';
  int _correctAnswersCount = 0; // Variable pour compter les bonnes réponses

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
    _loadQuestions(); // Charger les questions au démarrage
  }

  Future<void> _showFeedbackAnimation(bool isCorrect, String correctAnswer) async {
  final Color color = isCorrect ? Colors.green : Colors.red;
  final IconData icon = isCorrect ? Icons.check_circle : Icons.cancel;
  final String message = isCorrect 
      ? "Bonne réponse !" 
      : "Mauvaise réponse\nLa bonne réponse était : $correctAnswer";

  await showDialog(
    context: context,
    barrierDismissible: true, 
    builder: (BuildContext context) {
      return Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              )
            ],
          ),
        ),
      );
    },
  );
  _nextQuestion();
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
                  minimumSize: const Size(100, 100), // Make the button square
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
        );
        case "timeline":
          double selectedYear = double.parse(currentQuestion['options'][0]);
          double minYear = double.parse(currentQuestion['options'][0]);
          double maxYear = double.parse(currentQuestion['options'][1]);

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: [
                  // Frise chronologique avec le Slider
                  Slider(
                    value: selectedYear,
                    min: minYear,
                    max: maxYear,
                    divisions: (maxYear - minYear).toInt(),
                    label: selectedYear.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // Afficher l'année sélectionnée
                  Text(
                    'Année sélectionnée : ${selectedYear.toInt()}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  // Bouton de validation
                  ElevatedButton(
                    onPressed: _selectedAnswer.isEmpty
                        ? () {
                            _checkAnswer(
                                selectedYear.toInt().toString(),
                                currentQuestion['correct_answer']);
                          }
                        : null,
                    child: const Text(
                      'Valider',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              );
            },
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

    void _checkAnswer(String selectedOption, String correctAnswer) async {
      setState(() {
        if (selectedOption == correctAnswer) {
          _correctAnswersCount++; // Incrémenter le nombre de bonnes réponses
          _selectedAnswer = 'correct';
        } else {
          _selectedAnswer = 'incorrect';
        }
      });

      // Appeler l'animation de feedback
      await _showFeedbackAnimation(_selectedAnswer == 'correct', correctAnswer);
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
