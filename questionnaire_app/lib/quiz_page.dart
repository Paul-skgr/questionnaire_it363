import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/results/resultScreen.dart';

class QuizPage extends StatefulWidget {
  final List<String> selectedCategories;

  const QuizPage({super.key, required this.selectedCategories});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, List<Map<String, dynamic>>> questions;
  List<Map<String, dynamic>> quizQuestions = [];
  late List<Map<String, dynamic>> higherDifficultyQuestions;
  late Map<String, dynamic> storedQuestion;
  List<String> multipleChoices = [];
  int _currentQuestionIndex = 0;
  int _difficulty = 0;
  String _selectedAnswer = '';
  double _score = 0;
  double _scoreMax = 0;
  int _correctAnswersCount = 0;
  bool _isDiffChecked = false;
  String coordinatesList2 = ''; // Liste vide de coordonnées
  List<double> coordinatesList =[];
  List<String> correctCoordinates = [];
  List<String> correctCoordinatesCleaned = [];
  

  Future<void> _loadQuestionsFromFirestore() async {
    try {
      Map<String, List<Map<String, dynamic>>> loadedQuestions = {};

      for (String category in widget.selectedCategories) {
        QuerySnapshot snapshot = await _firestore.collection(category).get();
        List<Map<String, dynamic>> categoryQuestions = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        loadedQuestions[category] = categoryQuestions;
      }

      setState(() {
        questions = loadedQuestions;
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

        quizQuestions.shuffle(Random());
      });
    } catch (e) {
      print("Erreur lors du chargement des questions : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuestionsFromFirestore();
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.grey.withOpacity(0.7),
                ),
              ),
            ),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: 250,
                height: 300,
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
                        Navigator.of(context).pop();
                        _nextQuestion();
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
    try {
      switch (currentQuestion["type"]) {
        case "single-choice":
          return Column(
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    disabledBackgroundColor: backgroundColor,
                    minimumSize: const Size(500, 50),
                  ),
                  onPressed: _selectedAnswer.isEmpty
                      ? () {
                          _checkAnswer(
                              option,
                              currentQuestion['correct_answer'],
                              'single-choice',
                              currentQuestion['difficulty']);
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 500,
                      maxWidth: 700,
                    ),
                    child: CheckboxListTile(
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
                      title: Text(option, style: const TextStyle(fontSize: 18)),
                      controlAffinity: ListTileControlAffinity.trailing,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                      dense: true,
                    ),
                  ),
                );
              }),
              ElevatedButton(
                onPressed: _selectedAnswer.isEmpty
                    ? () {
                        _checkAnswer(
                            multipleChoices.join(','),
                            currentQuestion['correct_answer'],
                            'multiple-choice',
                            currentQuestion['difficulty']);
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
          return Center(
            child: SingleChildScrollView(
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

                  Color backgroundColor =
                      isSelectedCorrect || isSelectedIncorrect
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
                              _checkAnswer(
                                  option,
                                  currentQuestion['correct_answer'],
                                  'images',
                                  currentQuestion['difficulty']);
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
                  Text(
                    'Année sélectionnée : ${selectedYear.toInt()}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedAnswer.isEmpty
                        ? () {
                            _checkAnswer(
                                selectedYear.toInt().toString(),
                                currentQuestion['correct_answer'],
                                'timeline',
                                currentQuestion['difficulty']);
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

        case "map-q":
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Padding(
                //padding: const EdgeInsets.all(16.0),
                //child: Text(
                  //currentQuestion['question'], // Affiche la question sur la carte
                  //style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  //textAlign: TextAlign.center,
                //),
              //),
              Flexible(
                fit: FlexFit.loose,
                child: Center(
                  child: SizedBox(
                    width: 300, 
                    height: 400, 
                    child: GestureDetector(
                      onTapDown: (details) {
                        final tapX = details.localPosition.dx;
                        final tapY = details.localPosition.dy;
                    coordinatesList2=tapX.toString() + ',' +tapY.toString();
                    //List<String> correctCoordinates = currentQuestion['correct_answer'].split(',');
                    //List<String> correctCoordinatesCleaned = correctCoordinates.map((coord) => coord.trim()).toList();
                    //List<String> correctCoordinates = currentQuestion['correct_answer'].split(',');
                   // List<double> coordinatesList = [tapX, tapY];
                    // Vérifier si le clic est dans la zone correcte
                       // final isCorrect = (double.parse(correctCoordinatesCleaned[0]) - coordinatesList[0]).abs() < 4.0 &&
                          //  (double.parse(correctCoordinatesCleaned[1]) - coordinatesList[1]).abs() < 4.0;
                      
                      },
                      child: Stack(
                        children: [
                          Image.asset(
                            '${currentQuestion["images"]}',
                            fit: BoxFit.contain, // Adapte l'image à la taille
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          //Positioned(
                            //left: 150 - 6,
                            //top: 153 - 6,
                            //child: Container(
                              //width: 30 * 0.5,
                              //height: 30 * 0.5,
                              //decoration: BoxDecoration(
                                //color: Colors.red.withOpacity(0.3),
                               // border: Border.all(color: Colors.red, width: 2),
                             // ),
                           // ),
                         // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _selectedAnswer.isEmpty
                    ? () {
                        _checkAnswer(coordinatesList2, currentQuestion['correct_answer'], 'map-q', currentQuestion['difficulty']);
                      }
                    : null,
                child: const Text(
                  'Valider',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          );

        default:
          throw Exception("Type de question inconnu");
      }
    } catch (e) {
      print("Erreur lors de l'affichage des réponses : $e");
    }
    return const Center(
      child: Text(
        'Erreur lors de l\'affichage des réponses : $e',
        style: TextStyle(fontSize: 18, color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _nextQuestion() {
    try {
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
                    score: _score,
                    scoreMax: _scoreMax,
                    totalQuestions: quizQuestions.length,
                    correctAnswersCount: _correctAnswersCount)),
          );
        }
      });
    } catch (e) {
      print("Erreur lors du passage à la question suivante : $e");
      Navigator.pop(context); // Revenir au menu principal
    }
  }

  void _checkAnswer(String selectedOption, String correctAnswer, String type,
      int questionDifficulty) async {
    const double bonusBase = 0.5; // Base pour le bonus

    // Fonction pour calculer l'effet logarithmique de la difficulté
    double _getLogarithmicEffect(int difficulty) {
      return difficulty <= 0 ? 0 : 0 + log(difficulty);
    }

    try {
      switch (type) {
        case "multiple-choice":
          setState(() {
            List<String> selectedOptions = selectedOption.split(',');

            List<String> correctAnswers = correctAnswer.split(',');

            List<String> correctAnswersCleaned =
                correctAnswers.map((answer) => answer.trim()).toList();

            double logEffect = _getLogarithmicEffect(1 + questionDifficulty);

            if (correctAnswersCleaned
                    .toSet()
                    .containsAll(selectedOptions.toSet()) &&
                selectedOptions.length == correctAnswersCleaned.length) {
              _difficulty++;
              _correctAnswersCount++;
              _score += 1 +
                  logEffect *
                      bonusBase; // Gain logarithmique pour une bonne réponse
              _selectedAnswer = 'correct';
              _scoreMax += 1 + logEffect * bonusBase;
            } else {
              _selectedAnswer = 'incorrect';
              if (_difficulty > 0) {
                _difficulty--;
              }
              _scoreMax += 1;
            }
          });
          break;
        case "map-q":
          setState(() {
            List<String> selectedCoordinates = selectedOption.split(',');

    
            List<String> correctCoordinates = correctAnswer.split(',');

    
            List<String> correctCoordinatesCleaned = 
                correctCoordinates.map((coord) => coord.trim()).toList();

            // Logarithmic effect basé sur la difficulté
            double logEffect = _getLogarithmicEffect(1 + questionDifficulty);

            // Comparer les coordonnées sélectionnées avec les bonnes
           if (correctCoordinatesCleaned.length == selectedCoordinates.length &&
               (double.parse(correctCoordinatesCleaned[0]) - double.parse(selectedCoordinates[0])).abs()<=9.0 &&
               (double.parse(correctCoordinatesCleaned[1]) - double.parse(selectedCoordinates[1])).abs()<=9.0 ){
              _difficulty++;
              _correctAnswersCount++;
              _score += 1 + logEffect * bonusBase; // Gain logarithmique pour une bonne réponse
              _selectedAnswer = 'correct';
              _scoreMax += 1 + logEffect * bonusBase;
            } else {
              // Réponse incorrecte
              _selectedAnswer = 'incorrect';
              if (_difficulty > 0) {
                _difficulty--;
              }
              _scoreMax += 1;
            }
          });
          break;
        default:
          setState(() {
            double logEffect = _getLogarithmicEffect(1 + questionDifficulty);

            if (selectedOption == correctAnswer) {
              _correctAnswersCount++;
              _difficulty++;
              _score += 1 +
                  logEffect *
                      bonusBase; // Gain logarithmique pour une bonne réponse
              _selectedAnswer = 'correct';
              _scoreMax += 1 + logEffect * bonusBase;
            } else {
              _selectedAnswer = 'incorrect';
              if (_difficulty > 0) {
                _difficulty--;
              }
              _scoreMax += 1;
            }
          });
      }
      print("score $_score");

      await _showFeedbackAnimation(_selectedAnswer == 'correct', correctAnswer);
    } catch (e) {
      print("Erreur lors de la vérification de la réponse : $e");
    }
  }

  Map<String, dynamic> _getCurrentQuestion() {
    try {
      Map<String, dynamic> currentQuestion;

      if (!_isDiffChecked) {
        currentQuestion = quizQuestions[_currentQuestionIndex];
        int currentID = currentQuestion['id'];
        List<Map<String, dynamic>> matchingQuestions = higherDifficultyQuestions
            .where((question) => question['id'] == currentID)
            .toList();

        List<Map<String, dynamic>> filteredQuestions = matchingQuestions
            .where((question) => question['difficulty'] < _difficulty)
            .toList();

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
    } catch (e) {
      print('_isDiffChecked: $_isDiffChecked');
      print("Erreur lors de la récupération de la question actuelle : $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (quizQuestions.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: const Text('Quiz')),
          body: const Center(child: CircularProgressIndicator()),
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
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                onPressed: _currentQuestionIndex == quizQuestions.length - 1
                    ? null
                    : () => _nextQuestion(),
                child: const Text(
                  'Suivant',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print("Erreur lors de l'affichage de la question : $e");
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Text(
            'Erreur lors de l\'affichage de la question : $e',
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}