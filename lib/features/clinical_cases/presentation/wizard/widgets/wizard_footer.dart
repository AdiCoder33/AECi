import 'package:flutter/material.dart';

class WizardFooter extends StatelessWidget {
  const WizardFooter({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isNextEnabled,
    required this.onBack,
    required this.onNext,
    required this.onSaveDraft,
    required this.onSubmit,
  });

  final bool isFirst;
  final bool isLast;
  final bool isNextEnabled;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isLast
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSaveDraft,
                    child: const Text('Save Draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isNextEnabled ? onSubmit : null,
                    child: const Text('Submit Case'),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isFirst ? null : onBack,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isNextEnabled ? onNext : null,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
    );
  }
}
