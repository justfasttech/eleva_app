import 'package:flutter/material.dart';

import '../widgets/admin_quiz_tab.dart';

class AdminQuizzesPage extends StatelessWidget {
  const AdminQuizzesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              'Quizzes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(child: AdminQuizTab()),
        ],
      ),
    );
  }
}
