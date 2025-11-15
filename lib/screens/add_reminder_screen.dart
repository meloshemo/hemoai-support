import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
// Use repository layer (SSoT)
import '../repositories/reminder_repository.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';
import '../services/audit_log_service.dart';
import '../widgets/app_drawer.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  NotificationType _selectedType = NotificationType.general;
  RepeatType _selectedRepeat = RepeatType.none;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: scheme,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: scheme),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _getTypeDisplayName(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_medication');
      case NotificationType.test:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_test');
      case NotificationType.appointment:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_appointment');
      case NotificationType.reminder:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_general_reminder');
      case NotificationType.general:
        return Provider.of<LocalizationService>(context, listen: false).getString('reminder_type_general');
    }
  }

  String _getRepeatDisplayName(RepeatType type) {
    switch (type) {
      case RepeatType.none:
        return Provider.of<LocalizationService>(context, listen: false).getString('repeat_none');
      case RepeatType.daily:
        return Provider.of<LocalizationService>(context, listen: false).getString('repeat_daily');
      case RepeatType.weekly:
        return Provider.of<LocalizationService>(context, listen: false).getString('repeat_weekly');
      case RepeatType.monthly:
        return Provider.of<LocalizationService>(context, listen: false).getString('repeat_monthly');
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return Icons.medication;
      case NotificationType.test:
        return Icons.science;
      case NotificationType.appointment:
        return Icons.event;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capture context-dependent objects before any awaits
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final reminderRepository = Provider.of<ReminderRepository>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Database'e kaydet ve ID al
      int? newId;
      final prefs = await PreferencesService.getInstance();
      final userId = prefs.getCurrentUserId();
      if (userId != null) {
        newId = await reminderRepository.createReminder({
          'user_id': userId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'scheduled_time': scheduledDateTime.millisecondsSinceEpoch,
          'type': _selectedType.index,
          'repeat_type': _selectedRepeat.index,
          'is_active': 1,
        });
      }

      final notification = NotificationItem(
  id: newId, // guest ise null olabilir; service icinde atanacak
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledTime: scheduledDateTime,
        type: _selectedType,
        repeatType: _selectedRepeat,
      );
      await notificationService.addNotification(notification);

      // Audit log
      AuditLogService().logAction('reminder_created', data: {
        'id': newId,
        'title': _titleController.text.trim(),
        'type': _selectedType.toString(),
        'repeat': _selectedRepeat.toString(),
        'time': scheduledDateTime.toIso8601String(),
      });

      // Success feedback
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.getString('reminder_added_success')),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!mounted) return;
      navigator.pop();

    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${loc.getString('error_prefix')}${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: canPop ? null : const AppDrawer(currentRoute: '/add_reminder'),
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: localizationService.getString('back'),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu,
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: localizationService.getString('menu'),
                ),
              ),
        title: Text(
          localizationService.getString('add_reminder'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.alarm_add,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizationService.getString('new_reminder'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizationService.getString('reminder_header_description'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Form Fields
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: localizationService.getString('reminder_title_label'),
                          hintText: localizationService.getString('reminder_title_hint'),
                          prefixIcon: Icon(Icons.title, color: Theme.of(context).colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localizationService.getString('reminder_title_validate');
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: localizationService.getString('reminder_description_label'),
                          hintText: localizationService.getString('reminder_description_hint'),
                          prefixIcon: Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localizationService.getString('reminder_description_validate');
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Type Selector
                      DropdownButtonFormField<NotificationType>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: localizationService.getString('reminder_type_label'),
                          prefixIcon: Icon(_getTypeIcon(_selectedType), color: Theme.of(context).colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        items: NotificationType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getTypeIcon(type), size: 20),
                                const SizedBox(width: 12),
                                Text(_getTypeDisplayName(type)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // Date Selector
                      ListTile(
                        leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                        title: Text(localizationService.getString('date_label')),
                        subtitle: Text(
                          localizationService.formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _selectDate,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Time Selector
                      ListTile(
                        leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                        title: Text(localizationService.getString('time_label')),
                        subtitle: Text(
                          localizationService.formatTime(DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _selectedTime.hour,
                            _selectedTime.minute,
                          )),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _selectTime,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Repeat Selector
                      DropdownButtonFormField<RepeatType>(
                        initialValue: _selectedRepeat,
                        decoration: InputDecoration(
                          labelText: localizationService.getString('repeat_label'),
                          prefixIcon: Icon(Icons.repeat, color: Theme.of(context).colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        items: RepeatType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getRepeatDisplayName(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRepeat = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save),
                          const SizedBox(width: 8),
                          Text(
                            localizationService.getString('save_reminder_button'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}