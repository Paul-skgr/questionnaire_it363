import 'dart:convert';
import 'dart:math';
import 'dart:ui';
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
  List<String> multipleChoices = [];
  int _currentQuestionIndex = 0;
  int _difficulty = 0;
  String _selectedAnswer = '';
  int _correctAnswersCount = 0; // Variable pour compter les bonnes réponses
  bool _isDiffChecked = false;

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

  Future<void> _showFeedbackAnimation(
      bool isCorrect, String correctAnswer) async {
    final Color color = isCorrect ? Colors.green : Colors.red;
    final IconData icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final String message = isCorrect
        ? "Bonne réponse !"
        : "Mauvaise réponse\nLa bonne réponse était : $correctAnswer";

    await showDialog(
      context: context,
      barrierDismissible:
          false, // Ne permet pas de fermer la boîte de dialogue en dehors
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Couverture floue de l'arrière-plan
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 5.0, sigmaY: 5.0), // Appliquer un flou
                child: Container(
                  color: Colors.grey.withOpacity(0.7), // Fond semi-transparent
                ),
              ),
            ),
            // Animation au premier plan
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: 250,
                height: 300, // Augmenter la hauteur pour ajouter un bouton
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
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pop(); // Fermer la boîte de dialogue
                        _nextQuestion(); // Passer à la question suivante
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Suivant',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
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
                        _checkAnswer(option, currentQuestion['correct_answer'],
                            'single-choice');
                      }
                    : null,
                child: Text(option, style: const TextStyle(fontSize: 18)),
              ),
            );
          }).toList(),
        );
      case "multiple-choice":
        return Column(
          children: [
            ...options.map((option) {
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CheckboxListTile(
                  title: Text(option, style: const TextStyle(fontSize: 18)),
                  value: multipleChoices.contains(option),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        multipleChoices.add(option);
                      } else {
                        multipleChoices.remove(option);
                      }
                    });
                  },
                  activeColor: backgroundColor,
                  checkColor: Colors.white,
                ),
              );
            }).toList(),
            ElevatedButton(
              onPressed: _selectedAnswer.isEmpty
                  ? () {
                      _checkAnswer(multipleChoices.join(','),
                          currentQuestion['correct_answer'], 'multiple-choice');
                    }
                  : null,
              child: const Text(
                'Valider',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
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
                          _checkAnswer(option,
                              currentQuestion['correct_answer'], 'images');
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
                          _checkAnswer(selectedYear.toInt().toString(),
                              currentQuestion['correct_answer'], 'timeline');
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
        _selectedAnswer = '';
        _isDiffChecked = false;
        multipleChoices = [];
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

  void _checkAnswer(
      String selectedOption, String correctAnswer, String type) async {
    switch (type) {
      case "multiple-choice":
        setState(() {
          List<String> selectedOptions = selectedOption.split(',');

          List<String> correctAnswers = correctAnswer.split(',');

          List<String> correctAnswersCleaned =
              correctAnswers.map((answer) => answer.trim()).toList();

          if (correctAnswersCleaned
                  .toSet()
                  .containsAll(selectedOptions.toSet()) &&
              selectedOptions.length == correctAnswersCleaned.length) {
            _correctAnswersCount++; // Incrémenter le nombre de bonnes réponses
            _difficulty++;

            _selectedAnswer = 'correct';
          } else {
            _selectedAnswer = 'incorrect';
            if (_difficulty > 0) {
              _difficulty--;
            }
          }
        });
      default:
        setState(() {
          if (selectedOption == correctAnswer) {
            _correctAnswersCount++; // Incrémenter le nombre de bonnes réponses
            _difficulty++;

            _selectedAnswer = 'correct';
          } else {
            _selectedAnswer = 'incorrect';
            if (_difficulty > 0) {
              _difficulty--;
            }
          }
        });
    }

    // Appeler l'animation de feedback
    await _showFeedbackAnimation(_selectedAnswer == 'correct', correctAnswer);
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
              onPressed: () => _nextQuestion(),
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
