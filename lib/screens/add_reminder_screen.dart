import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/web_database_helper.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';
import '../services/audit_log_service.dart';
import '../widgets/app_drawer.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({Key? key}) : super(key: key);

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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFE53E3E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFE53E3E),
              onPrimary: Colors.white,
            ),
          ),
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
        newId = await WebDatabaseHelper.instance.createReminder({
          'user_id': userId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'scheduled_time': scheduledDateTime.millisecondsSinceEpoch,
          'type': _selectedType.index,
          'repeat_type': _selectedRepeat.index,
          'is_active': 1,
        });
      }

      // NotificationService'e ekle (DB'den dönen ID ile)
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final notification = NotificationItem(
        id: newId, // guest ise null olabilir; service içinde atanacak
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
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getString('reminder_added_success')),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.getString('error_prefix')}${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF0D1117) 
        : Colors.grey[50],
      drawer: const AppDrawer(currentRoute: '/add_reminder'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
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
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22) 
          : const Color(0xFFE53E3E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                        color: const Color(0xFFE53E3E),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizationService.getString('new_reminder'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE53E3E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizationService.getString('reminder_header_description'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
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
                          prefixIcon: const Icon(Icons.title, color: Color(0xFFE53E3E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53E3E)),
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
                          prefixIcon: const Icon(Icons.description, color: Color(0xFFE53E3E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53E3E)),
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
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: localizationService.getString('reminder_type_label'),
                          prefixIcon: Icon(_getTypeIcon(_selectedType), color: const Color(0xFFE53E3E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53E3E)),
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
                        leading: const Icon(Icons.calendar_today, color: Color(0xFFE53E3E)),
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
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Time Selector
                      ListTile(
                        leading: const Icon(Icons.access_time, color: Color(0xFFE53E3E)),
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
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Repeat Selector
                      DropdownButtonFormField<RepeatType>(
                        value: _selectedRepeat,
                        decoration: InputDecoration(
                          labelText: localizationService.getString('repeat_label'),
                          prefixIcon: const Icon(Icons.repeat, color: Color(0xFFE53E3E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53E3E)),
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
                  backgroundColor: const Color(0xFFE53E3E),
                  foregroundColor: Colors.white,
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