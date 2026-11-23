import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/features/life_os/presentation/controllers/life_os_center_cubit.dart';
import 'package:solducci/theme/app_theme.dart';

class UniversalCaptureSheet extends StatefulWidget {
  final LifeOsCenterCubit cubit;

  const UniversalCaptureSheet({super.key, required this.cubit});

  static Future<bool?> show(BuildContext context, {required LifeOsCenterCubit cubit}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UniversalCaptureSheet(cubit: cubit),
    );
  }

  @override
  State<UniversalCaptureSheet> createState() => _UniversalCaptureSheetState();
}

class _UniversalCaptureSheetState extends State<UniversalCaptureSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _isSaving) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final success = await widget.cubit.captureSeed(
      title,
      description: _descController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = widget.cubit.state.captureError ??
              'Impossibile salvare: connessione assente o errore.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.eco_outlined, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Cattura Rapida LifeOS',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isSaving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                )
              else
                TextButton(
                  onPressed: _submit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Salva Seme'),
                ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Cosa ti passa per la testa? (Seme)',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 16),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Dettagli o contesto opzionale...',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
