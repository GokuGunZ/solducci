import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solducci/core/onboarding/models/onboarding_config.dart';

class FeatureOnboardingWizard extends StatefulWidget {
  final OnboardingConfig config;
  final Future<void> Function(String selectedOptionId) onComplete;

  const FeatureOnboardingWizard({
    Key? key,
    required this.config,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FeatureOnboardingWizard> createState() => _FeatureOnboardingWizardState();
}

class _FeatureOnboardingWizardState extends State<FeatureOnboardingWizard> {
  int _currentStep = 0; // 0 = Presentation, 1 = Options
  String? _selectedOptionId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-select default option if any
    try {
      final defaultOpt = widget.config.options.firstWhere((o) => o.isDefault);
      _selectedOptionId = defaultOpt.id;
    } catch (_) {
      if (widget.config.options.isNotEmpty) {
        _selectedOptionId = widget.config.options.first.id;
      }
    }
  }

  void _showInfoModal() {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.config.infoModalTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.config.infoModalContent,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Ho capito', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                ),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _currentStep == 0 ? _buildPresentationStep() : _buildOptionsStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationStep() {
    return Container(
      key: const ValueKey('step_0'),
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            widget.config.presentationTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.config.presentationSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Inizia a creare',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOptionsStep() {
    return Container(
      key: const ValueKey('step_1'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              IconButton(
                onPressed: _showInfoModal,
                icon: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Scegli il tuo Setup',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Come preferisci iniziare?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: widget.config.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final option = widget.config.options[index];
                final isSelected = _selectedOptionId == option.id;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedOptionId = option.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: Image.asset(
                            option.heroImageAssetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(color: Colors.black26),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                option.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_selectedOptionId != null) {
                  setState(() => _isLoading = true);
                  try {
                    await widget.onComplete(_selectedOptionId!);
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                disabledBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Crea il mio spazio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
