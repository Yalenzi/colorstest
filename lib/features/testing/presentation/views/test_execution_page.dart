// Legacy stub — this file satisfies the import in test_overview_page.dart.
// The canonical test execution flow is in:
//   lib/features/reagent_testing/presentation/views/test_execution_page.dart

import 'package:flutter/material.dart';
import '../../data/models/reagent_model.dart';

class TestExecutionPage extends StatelessWidget {
  final ReagentModel reagent;

  const TestExecutionPage({super.key, required this.reagent});

  @override
  Widget build(BuildContext context) {
    // Redirect to the canonical test execution experience.
    return Scaffold(
      appBar: AppBar(title: Text(reagent.name)),
      body: const Center(
        child: Text(
          'Use the main Reagent Testing tab to run tests.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
