import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portfolio_ai/presentation/providers/portfolio_provider.dart';
import 'package:portfolio_ai/presentation/widgets/loading_animation.dart';

class BuilderWizardScreen extends ConsumerStatefulWidget {
  const BuilderWizardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BuilderWizardScreen> createState() => _BuilderWizardScreenState();
}

class _BuilderWizardScreenState extends ConsumerState<BuilderWizardScreen> {
  
  @override
  Widget build(BuildContext context) {
    final portfolioState = ref.watch(portfolioProvider);

    // Auto navigate to preview if compilation completes successfully
    ref.listen(portfolioProvider, (previous, next) {
      if (next.generatedUrl != null && !next.isLoading) {
        Navigator.pushReplacementNamed(context, '/preview');
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Agentic Compilation Pipeline'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OrchestrationPipelineLoader(steps: portfolioState.pipelineSteps),
                const SizedBox(height: 24),
                if (portfolioState.error != null) ...[
                  Text(
                    'Error: ${portfolioState.error}',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
