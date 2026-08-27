
class OnboardingOption {
  final String id;
  final String title;
  final String description;
  final String heroImageAssetPath;
  final bool isDefault;

  const OnboardingOption({
    required this.id,
    required this.title,
    required this.description,
    required this.heroImageAssetPath,
    this.isDefault = false,
  });
}

class OnboardingConfig {
  final String featureKey;
  final String presentationTitle;
  final String presentationSubtitle;
  final String presentationImageAssetPath;
  final String infoModalTitle;
  final String infoModalContent;
  final List<OnboardingOption> options;

  const OnboardingConfig({
    required this.featureKey,
    required this.presentationTitle,
    required this.presentationSubtitle,
    required this.presentationImageAssetPath,
    required this.infoModalTitle,
    required this.infoModalContent,
    required this.options,
  });
}
