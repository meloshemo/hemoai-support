import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ai_diet_menu_service.dart';
import '../services/localization_service.dart';

class MedicalDisclaimerBanner extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const MedicalDisclaimerBanner({
    super.key,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Container(
          margin: margin ?? const EdgeInsets.only(bottom: 16),
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localization.getString('medical_disclaimer'),
                      style: TextStyle(
                        color: colorScheme.error.darken(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                localization.getString('medical_disclaimer_desc'),
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localization.getString('medical_disclaimer_body'),
                style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 4),
              Text(
                localization.getString('medical_consult_prompt'),
                style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emergency, size: 18, color: colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      localization.getString('medical_emergency_cta'),
                      style: TextStyle(
                        color: colorScheme.error.darken(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class DietPlanSafetyAlert extends StatelessWidget {
  final DietPlanSafetyReport? report;
  final EdgeInsetsGeometry? margin;

  const DietPlanSafetyAlert({
    super.key,
    required this.report,
    this.margin,
  });

  bool get _shouldDisplay {
    if (report == null) return false;
    return report!.requiresClinicalReview ||
        report!.warningKeys.isNotEmpty ||
        report!.guidelineKeys.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldDisplay) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final currentReport = report!;

    return Consumer<LocalizationService>(
      builder: (context, localization, _) {
        final title = currentReport.requiresClinicalReview
            ? localization.getString('medical_review_required_title')
            : localization.getString('medical_review_info_title');
        final subtitle = currentReport.requiresClinicalReview
            ? localization.getString('medical_review_required_body')
            : localization.getString('medical_review_info_body');

        return Semantics(
          label: title,
          hint: subtitle,
          liveRegion: true,
          container: true,
          child: Container(
            margin: margin ?? const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.tertiary.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.tertiary,
                      semanticLabel: title,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: colorScheme.tertiary.darken(),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (currentReport.warningKeys.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...currentReport.warningKeys.map(
                    (key) => _SafetyBullet(
                      text: localization.getString(key),
                      color: colorScheme.error.darken(),
                    ),
                  ),
                ],
                if (currentReport.guidelineKeys.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    localization.getString('medical_guideline_reference_title'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...currentReport.guidelineKeys.map(
                    (key) => _SafetyBullet(
                      text: localization.getString(key),
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SafetyBullet extends StatelessWidget {
  final String text;
  final Color color;

  const _SafetyBullet({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color.darken();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _ColorDarken on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
