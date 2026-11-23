import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/service/markdown_settings_service.dart';

class MarkdownViewerSettingsSheet extends StatefulWidget {
  const MarkdownViewerSettingsSheet({super.key});

  static Future<void> show(BuildContext context) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const MarkdownViewerSettingsSheet(),
    );
  }

  @override
  State<MarkdownViewerSettingsSheet> createState() => _MarkdownViewerSettingsSheetState();
}

class _MarkdownViewerSettingsSheetState extends State<MarkdownViewerSettingsSheet> {
  final _service = MarkdownSettingsService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle drag indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Impostazioni Visualizzatore MD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
                    tooltip: 'Ripristina predefiniti',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _service.resetDefaults();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Setting 1: Default Open
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Documento aperto di default',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mostra subito il contenuto completo anziché collassare la tile.',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _service.defaultExpanded,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        _service.setDefaultExpanded(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Setting 2: Font Size Slider
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dimensione Testo',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_service.fontSize.toStringAsFixed(1)} pt',
                            style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF6366F1),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: const Color(0xFF818CF8),
                        overlayColor: const Color(0xFF6366F1).withOpacity(0.15),
                      ),
                      child: Slider(
                        value: _service.fontSize,
                        min: 11.0,
                        max: 24.0,
                        divisions: 26,
                        onChanged: (val) {
                          _service.setFontSize(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Setting 3: Read-Only Lock
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Blocca Modifiche (Sola Lettura)',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Disabilita il trascinamento dell\'onda per evitare aperture accidentali dell\'editor.',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _service.readOnlyLock,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        _service.setReadOnlyLock(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
