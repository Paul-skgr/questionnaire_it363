import 'package:flutter/material.dart';
import 'quiz_page.dart';  // Import de la page Quiz

void main() {
  runApp(MyApp());
}

MaterialColor whiteMaterialColor = MaterialColor(
  0xFFFFFFFF,
  <int, Color>{
    50: Color(0xFFFFFFFF),  // Teinte très claire
    100: Color(0xFFFFFFFF), // Teinte claire
    200: Color(0xFFFFFFFF), // Teinte moyenne claire
    300: Color(0xFFFFFFFF), // Teinte moyenne
    400: Color(0xFFFFFFFF), // Teinte plus foncée
    500: Color(0xFFFFFFFF), // Couleur de base (blanc)
    600: Color(0xFFFFFFFF), // Teinte plus foncée
    700: Color(0xFFFFFFFF), // Teinte encore plus foncée
    800: Color(0xFFFFFFFF), // Teinte encore plus foncée
    900: Color(0xFFFFFFFF), // Teinte la plus foncée
  },
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: whiteMaterialColor,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, bool> categories = {
    'Histoire': false,
    'Sport': false,
    'Sciences': false,
    'Loisirs': false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page d\'accueil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sélectionner les catégories du quiz',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Column(
              children: categories.keys.map((category) {
                return CheckboxListTile(
                  title: Text(category),
                  value: categories[category],
                  onChanged: (bool? value) {
                    setState(() {
                      categories[category] = value!;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startQuiz,
              child: Text('Commencer le quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
