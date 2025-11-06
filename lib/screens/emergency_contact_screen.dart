import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../widgets/app_drawer.dart';
import 'dart:async';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final prefs = await PreferencesService.getInstance();
    _currentUserId = prefs.getCurrentUserId();
    await _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      // Get emergency contacts from database
      final contacts = await _dbHelper.getEmergencyContacts(_currentUserId);
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addContact(BuildContext context) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('add_emergency_contact')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: loc.getString('contact_name'),
                  hintText: loc.getString('contact_name_hint'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: loc.getString('contact_phone'),
                  hintText: '+90 555 123 4567',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationController,
                decoration: InputDecoration(
                  labelText: loc.getString('relation'),
                  hintText: loc.getString('relation_hint'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.getString('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  phoneController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'relation': relationController.text.isNotEmpty 
                      ? relationController.text 
                      : loc.getString('emergency_contact_default'),
                });
              }
            },
            child: Text(loc.getString('add')),
          ),
        ],
      ),
    );

    if (result != null && _currentUserId != null) {
      await _dbHelper.addEmergencyContact(
        userId: _currentUserId!,
        name: result['name']!,
        phone: result['phone']!,
        relation: result['relation']!,
      );
      await _loadContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('contact_added')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteContact(int id) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('delete_contact')),
        content: Text(loc.getString('delete_contact_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.getString('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(loc.getString('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteEmergencyContact(id);
      await _loadContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getString('contact_deleted')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, loc, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final scheme = theme.colorScheme;

        return Directionality(
          textDirection: loc.textDirection,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
            drawer: const AppDrawer(currentRoute: '/settings'),
            appBar: AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text(loc.getString('health_emergency_contact')),
              backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              elevation: 0,
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? _buildEmptyState(loc, theme, isDark)
                    : _buildContactsList(loc, theme, isDark, scheme),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _addContact(context),
              icon: const Icon(Icons.add),
              label: Text(loc.getString('add_contact')),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(LocalizationService loc, ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emergency_outlined,
            size: 100,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            loc.getString('no_emergency_contacts'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.getString('add_emergency_contact_desc'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(
    LocalizationService loc,
    ThemeData theme,
    bool isDark,
    ColorScheme scheme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isDark ? const Color(0xFF21262D) : Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE53E3E).withValues(alpha: 0.2),
              child: Icon(
                Icons.person_outline,
                color: const Color(0xFFE53E3E),
              ),
            ),
            title: Text(
              contact['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      contact['phone'] ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.label_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      contact['relation'] ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              onPressed: () => _deleteContact(contact['id']),
            ),
          ),
        );
      },
    );
  }
}

