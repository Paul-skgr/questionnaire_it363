import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
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

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> questions = [];
  List<String> selectedOptions = []; // Liste pour suivre les réponses sélectionnées

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  // Fonction pour charger les questions depuis le fichier JSON
  Future<void> loadQuestions() async {
    final String response = await rootBundle.loadString('assets/questions.json');
    final data = json.decode(response);
    setState(() {
      questions = data['questions'];
      selectedOptions = List<String>.filled(questions.length, ''); // Initialisation des réponses sélectionnées
    });
  }

  // Fonction pour gérer la sélection d'une option
  void selectOption(int questionIndex, String option) {
    setState(() {
      selectedOptions[questionIndex] = option;
    });

    // Vérifie si la réponse sélectionnée est correcte
    bool isCorrect = questions[questionIndex]['correct_answer'] == option;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Bonne réponse !' : 'Mauvaise réponse.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Culture Générale'),
      ),
      body: questions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question['question'],
                          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.0),
                        ...List.generate(
                          question['options'].length,
                          (i) => InkWell(
                            onTap: () => selectOption(index, question['options'][i]),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                              margin: EdgeInsets.symmetric(vertical: 4.0),
                              decoration: BoxDecoration(
                                color: selectedOptions[index] == question['options'][i]
                                    ? Colors.blue.shade100
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
                );
              },
            ),
    );
  }
}
