import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../share_extension_handler.dart';

class ShareExtensionView extends ConsumerStatefulWidget {
  const ShareExtensionView({super.key});

  @override
  ConsumerState<ShareExtensionView> createState() => _ShareExtensionViewState();
}

class _ShareExtensionViewState extends ConsumerState<ShareExtensionView> {
  bool _isSaving = false;
  String? _errorMessage;
  bool _saveCompleted = false;

  @override
  void initState() {
    super.initState();
    // Auto-close after successful save
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_saveCompleted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSaving) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Saving content...',
                  style: TextStyle(fontSize: 16),
                ),
              ] else if (_errorMessage != null) ...[
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to save',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ] else if (_saveCompleted) ...[
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Saved successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Content will be processed in the background',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void setSaving(bool saving) {
    setState(() {
      _isSaving = saving;
    });
  }

  void setError(String message) {
    setState(() {
      _errorMessage = message;
      _isSaving = false;
    });
  }

  void setCompleted() {
    setState(() {
      _saveCompleted = true;
      _isSaving = false;
    });
  }
}

class SaveProgressIndicator extends StatelessWidget {
  final String? message;
  final double? progress;

  const SaveProgressIndicator({
    super.key,
    this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress != null)
            CircularProgressIndicator(value: progress)
          else
            const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              message ?? 'Processing...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}