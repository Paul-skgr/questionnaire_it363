import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'resultScreen.dart';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> questions = [];
  List<String> selectedOptions = [];
  PageController _pageController = PageController();
  Color answerColor = Colors.white;
  int correctAnswers = 0; // Nombre de réponses correctes

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  // Charger les questions depuis le fichier JSON
  Future<void> loadQuestions() async {
    final String response =
        await rootBundle.loadString('assets/questions.json');
    final data = json.decode(response);
    setState(() {
      questions = data['questions'];

      // Mélanger les questions dans un ordre aléatoire
      questions.shuffle(Random());

      // Mélanger également les options de chaque question
      for (var question in questions) {
        question['options'].shuffle(Random());
      }

      selectedOptions = List<String>.filled(questions.length, '');
    });
  }

  // Fonction pour gérer la sélection d'une option
  void selectOption(int questionIndex, String option) {
    bool isCorrect = questions[questionIndex]['correct_answer'] == option;

    setState(() {
      answerColor = isCorrect ? Colors.green : Colors.red;
      selectedOptions[questionIndex] =
          option; // Mettre à jour la réponse sélectionnée
      if (isCorrect) {
        correctAnswers++; // Augmenter le score pour une bonne réponse
      }
    });

    // Afficher la couleur pour un court instant avant de passer à la question suivante
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        answerColor = Colors.white; // Réinitialiser la couleur
      });
      if (questionIndex < questions.length - 1) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Naviguer vers la page de résultats une fois le quiz terminé
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              totalQuestions: questions.length,
              correctAnswers: correctAnswers,
              onRestart: _restartQuiz, // Passer la fonction pour réinitialiser
            ),
          ),
        );
      }
    });
  }

  // Réinitialiser les variables du quiz
  void _restartQuiz() {
    setState(() {
      correctAnswers = 0;
      selectedOptions = List<String>.filled(questions.length, '');
      _pageController.jumpToPage(0); // Revenir à la première question
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Culture Générale'),
      ),
      body: questions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: questions.length,
              physics:
                  NeverScrollableScrollPhysics(), // Désactiver le défilement manuel
              itemBuilder: (context, index) {
                final question = questions[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Centrer horizontalement
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Centrer verticalement
                    children: [
                      // Centrer le texte de la question
                      Center(
                        child: Text(
                          question['question'],
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                          textAlign: TextAlign
                              .center, // Centrer le texte horizontalement
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // Centrer les boutons
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ...List.generate(
                                question['options'].length,
                                (i) => GestureDetector(
                                  onTap: () => selectOption(
                                      index, question['options'][i]),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 16.0),
                                    margin: EdgeInsets.symmetric(vertical: 6.0),
                                    decoration: BoxDecoration(
                                      color: selectedOptions[index] ==
                                              question['options'][i]
                                          ? answerColor
                                          : Colors.white,
                                      border: Border.all(color: Colors.blue),
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    child: Text(question['options'][i]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Culture Générale',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: QuizScreen(),
    );
  }
}
