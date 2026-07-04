import 'package:flutter/material.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/presentation/widgets/glass_card.dart';

class PipelineStep {
  final String title;
  final String description;
  final String status; // 'pending', 'running', 'completed', 'failed'

  PipelineStep({
    required this.title,
    required this.description,
    required this.status,
  });
}

class OrchestrationPipelineLoader extends StatelessWidget {
  final List<PipelineStep> steps;

  const OrchestrationPipelineLoader({
    Key? key,
    required this.steps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'AI Agents Working...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return _buildStepItem(context, step, index == steps.length - 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, PipelineStep step, bool isLast) {
    Color iconColor;
    Widget statusWidget;
    
    switch (step.status) {
      case 'completed':
        iconColor = AppTheme.neonCyan;
        statusWidget = const Icon(Icons.check_circle, color: AppTheme.neonCyan, size: 20);
        break;
      case 'running':
        iconColor = AppTheme.neonPurple;
        statusWidget = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonPurple)),
        );
        break;
      case 'failed':
        iconColor = Colors.redAccent;
        statusWidget = const Icon(Icons.error, color: Colors.redAccent, size: 20);
        break;
      default:
        iconColor = Colors.white24;
        statusWidget = const Icon(Icons.circle_outlined, color: Colors.white24, size: 20);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
                boxShadow: step.status == 'running' ? [
                  const BoxShadow(color: AppTheme.neonPurple, blurRadius: 8, spreadRadius: 2),
                ] : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: step.status == 'completed' ? AppTheme.neonCyan.withOpacity(0.5) : Colors.white12,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: step.status == 'running' ? Colors.white : Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.description,
                style: TextStyle(
                  fontSize: 12,
                  color: step.status == 'running' ? Colors.white70 : Colors.white30,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        statusWidget,
      ],
    );
  }
}
