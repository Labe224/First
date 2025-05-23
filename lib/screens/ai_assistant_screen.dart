import 'package:flutter/material.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _questionController = TextEditingController();
  String _aiResponse = '';
  bool _isLoading = false;

  void _askAI() {
    if (_questionController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _aiResponse = ''; // Clear previous response
    });

    // Simuler un appel API
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _aiResponse = 'Ceci est une réponse simulée de l\'IA à la question : "${_questionController.text}". L\'IA pourrait ici fournir un résumé ou une réponse détaillée basée sur les documents sélectionnés.';
        _isLoading = false;
        _questionController.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // TODO: Ajouter une section pour sélectionner les documents à analyser
            Text(
              'Posez une question sur vos documents ou demandez un résumé.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Votre question ou demande...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _isLoading ? null : _askAI,
                ),
              ),
              onSubmitted: _isLoading ? null : (_) => _askAI(),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_aiResponse.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                  ),
                  child: ListView(
                    children: [
                      Text(
                        'Réponse de l\'Assistant:',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_aiResponse, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            const Spacer(), // Pour pousser le contenu vers le haut
          ],
        ),
      ),
    );
  }
} 