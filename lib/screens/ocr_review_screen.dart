import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/analytics_service.dart';
import '../services/performance_service.dart';

/// OCR Review & Edit screen for validating and correcting extracted values
class OCRReviewScreen extends StatefulWidget {
  final Map<String, String> extractedValues;
  final String sourceImagePath;
  final Function(Map<String, double>) onConfirm;

  const OCRReviewScreen({
    super.key,
    required this.extractedValues,
    required this.sourceImagePath,
    required this.onConfirm,
  });

  @override
  State<OCRReviewScreen> createState() => _OCRReviewScreenState();
}

class _OCRReviewScreenState extends State<OCRReviewScreen>
    with TickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, bool> _hasWarnings = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isProcessing = false;

  // Parameter reference ranges for validation
  final Map<String, Map<String, double>> _referenceRanges = {
    'hemoglobin': {'min': 12.0, 'max': 17.0},
    'iron': {'min': 60.0, 'max': 170.0},
    'white_blood_cells': {'min': 4.0, 'max': 11.0},
    'red_blood_cells': {'min': 4.5, 'max': 5.9},
    'platelets': {'min': 150.0, 'max': 450.0},
    'hematocrit': {'min': 35.0, 'max': 50.0},
    'mcv': {'min': 80.0, 'max': 100.0},
    'mch': {'min': 27.0, 'max': 32.0},
    'mchc': {'min': 32.0, 'max': 36.0},
    'rdw': {'min': 11.5, 'max': 14.5},
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    
    // Track OCR review start
    Provider.of<AnalyticsService>(context, listen: false).trackEvent(
      'ocr_review_started',
      parameters: {
        'extracted_fields_count': widget.extractedValues.length,
        'has_image': widget.sourceImagePath.isNotEmpty,
      },
    );
  }

  void _initializeControllers() {
    for (final entry in widget.extractedValues.entries) {
      _controllers[entry.key] = TextEditingController(text: entry.value);
      _focusNodes[entry.key] = FocusNode();
      _validateField(entry.key, entry.value);
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes to prevent memory leaks
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _animationController.dispose();
    _controllers.clear();
    _focusNodes.clear();
    super.dispose();
  }

  void _validateField(String key, String value) {
    final numValue = double.tryParse(value);
    final range = _referenceRanges[key];
    
    bool hasWarning = false;
    if (numValue == null) {
      hasWarning = true; // Invalid number
    } else if (range != null) {
      hasWarning = numValue < range['min']! || numValue > range['max']!;
    }
    
    setState(() {
      _hasWarnings[key] = hasWarning;
    });
  }

  Future<void> _confirmValues() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final confirmed = <String, double>{};
    final warnings = <String>[];
    
    // Validate and collect all values
    for (final entry in _controllers.entries) {
      final key = entry.key;
      final text = entry.value.text.trim();
      final numValue = double.tryParse(text);
      
      if (numValue != null) {
        confirmed[key] = numValue;
        if (_hasWarnings[key] == true) {
          warnings.add(key);
        }
      }
    }

    // Use performance service for any heavy processing
    try {
      await PerformanceService().processInBackground<void>(
        taskId: 'ocr_confirm_processing',
        computation: () async {
          // Simulate processing time for validation
          await Future.delayed(const Duration(milliseconds: 500));
          return;
        },
      );

      analytics.trackEvent('ocr_review_confirmed', parameters: {
        'confirmed_fields_count': confirmed.length,
        'warning_fields_count': warnings.length,
        'original_fields_count': widget.extractedValues.length,
        'accuracy_rate': confirmed.length / widget.extractedValues.length,
      });

      if (mounted) {
        widget.onConfirm(confirmed);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      analytics.trackEvent('ocr_review_failed', parameters: {
        'error': e.toString(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LocalizationService>(context, listen: false)
                .getString('ocr_processing_error')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('ocr_review_title')),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        actions: [
          if (widget.sourceImagePath.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.image),
              tooltip: loc.getString('view_source_image'),
              onPressed: () => _showSourceImage(),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header with instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: scheme.primaryContainer.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fact_check, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        loc.getString('ocr_review_instructions'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.getString('ocr_review_description'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            // Fields list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  final key = _controllers.keys.elementAt(index);
                  return _buildFieldEditor(key, loc, theme, scheme);
                },
              ),
            ),
            
            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.2))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasWarnings.values.any((w) => w)) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.getString('ocr_review_warnings'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : () {
                            Provider.of<AnalyticsService>(context, listen: false)
                                .trackEvent('ocr_review_cancelled');
                            Navigator.of(context).pop(false);
                          },
                          child: Text(loc.getString('cancel')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _confirmValues,
                          icon: _isProcessing
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: Text(_isProcessing
                              ? loc.getString('processing')
                              : loc.getString('confirm_values')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldEditor(String key, LocalizationService loc, ThemeData theme, ColorScheme scheme) {
    final controller = _controllers[key]!;
    final focusNode = _focusNodes[key]!;
    final hasWarning = _hasWarnings[key] ?? false;
    final range = _referenceRanges[key];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasWarning 
              ? Colors.orange
              : scheme.outline.withValues(alpha: 0.2),
          width: hasWarning ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _getParameterDisplayName(key, loc),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasWarning)
                Icon(Icons.warning, color: Colors.orange, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: loc.getString('enter_value'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) => _validateField(key, value),
          ),
          if (range != null) ...[
            const SizedBox(height: 4),
            Text(
              loc.getStringWithParams('normal_range_template', {
                'min': range['min']!.toStringAsFixed(1),
                'max': range['max']!.toStringAsFixed(1),
              }),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          if (hasWarning) ...[
            const SizedBox(height: 4),
            Text(
              loc.getString('value_outside_normal_range'),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }

  String _getParameterDisplayName(String key, LocalizationService loc) {
    // Use existing localization keys for parameter names
    return loc.getString(key);
  }

  void _showSourceImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(Provider.of<LocalizationService>(context, listen: false)
                  .getString('source_image')),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.asset(
                  widget.sourceImagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}