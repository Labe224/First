import 'package:flutter/material.dart';
import '../models/document.dart'; // Importer le modèle Document

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? _selectedCategory;
  // TODO: Charger les documents existants pour les proposer à la sélection
  List<Document> _availableDocuments = []; // Simulé pour l'instant
  Document? _selectedDocumentForQuiz;
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _quizQuestions = []; // Simulé
  bool _quizStarted = false;
  Map<int, String> _selectedAnswers = {};
  int _score = 0;
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    // Simuler le chargement des documents et des catégories
    _availableDocuments = [
      Document(title: 'Rapport Annuel 2023', description: '...', category: 'Rapports', tags: []),
      Document(title: 'Contrat de Maintenance', description: '...', category: 'Contrats', tags: []),
    ];
  }

  void _startQuiz() {
    if (_selectedDocumentForQuiz == null) return;
    // Simuler la génération de questions basées sur le document
    setState(() {
      _quizQuestions = [
        {
          'question': 'Quelle est la conclusion principale du ${_selectedDocumentForQuiz!.title}?',
          'options': ['Conclusion A', 'Conclusion B', 'Conclusion C', 'Conclusion D'],
          'correctAnswer': 'Conclusion B'
        },
        {
          'question': 'Quelle date est mentionnée comme importante dans le document?',
          'options': ['01/01/2023', '15/06/2023', '31/12/2023', 'Aucune date spécifique'],
          'correctAnswer': '15/06/2023'
        },
      ];
      _quizStarted = true;
      _quizFinished = false;
      _currentQuestionIndex = 0;
      _selectedAnswers = {};
      _score = 0;
    });
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_selectedAnswers[_currentQuestionIndex] == _quizQuestions[_currentQuestionIndex]['correctAnswer']) {
      _score++;
    }
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _quizFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _quizStarted && !_quizFinished
            ? _buildQuizView(theme)
            : _quizFinished
                ? _buildQuizResultView(theme)
                : _buildQuizSetupView(theme),
      ),
    );
  }

  Widget _buildQuizSetupView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Préparez un quiz sur un document spécifique.', style: theme.textTheme.titleMedium),
        const SizedBox(height: 20),
        // Sélecteur de catégorie (facultatif, ou filtrer les documents par catégorie)
        DropdownButtonFormField<Document>(
          decoration: const InputDecoration(labelText: 'Sélectionner un document'),
          value: _selectedDocumentForQuiz,
          items: _availableDocuments.map((Document doc) {
            return DropdownMenuItem<Document>(
              value: doc,
              child: Text(doc.title, style: theme.textTheme.bodyMedium),
            );
          }).toList(),
          onChanged: (Document? newValue) {
            setState(() {
              _selectedDocumentForQuiz = newValue;
            });
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Commencer le Quiz'),
            onPressed: _selectedDocumentForQuiz == null ? null : _startQuiz,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizView(ThemeData theme) {
    final questionData = _quizQuestions[_currentQuestionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Question ${_currentQuestionIndex + 1}/${_quizQuestions.length}', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(questionData['question'], style: theme.textTheme.titleMedium),
        const SizedBox(height: 20),
        ...(questionData['options'] as List<String>).map((option) {
          return RadioListTile<String>(
            title: Text(option, style: theme.textTheme.bodyMedium),
            value: option,
            groupValue: _selectedAnswers[_currentQuestionIndex],
            onChanged: (String? value) {
              if (value != null) _selectAnswer(value);
            },
          );
        }).toList(),
        const Spacer(),
        Center(
          child: ElevatedButton(
            child: Text(_currentQuestionIndex < _quizQuestions.length - 1 ? 'Question Suivante' : 'Terminer'),
            onPressed: _selectedAnswers[_currentQuestionIndex] == null ? null : _nextQuestion,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildQuizResultView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Quiz Terminé!', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 20),
          Text('Votre score: $_score / ${_quizQuestions.length}', style: theme.textTheme.titleLarge),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Recommencer un Quiz'),
            onPressed: () {
              setState(() {
                _quizStarted = false;
                _quizFinished = false;
                _selectedDocumentForQuiz = null; // Permet de rechoisir
              });
            },
          ),
        ],
      ),
    );
  }
} 