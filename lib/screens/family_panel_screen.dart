import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/web_database_helper.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';

class FamilyPanelScreen extends StatefulWidget {
  const FamilyPanelScreen({Key? key}) : super(key: key);

  @override
  State<FamilyPanelScreen> createState() => _FamilyPanelScreenState();
}

class _FamilyPanelScreenState extends State<FamilyPanelScreen> {
  PreferencesService? _prefsService;
  final WebDatabaseHelper _dbHelper = WebDatabaseHelper.instance;
  List<Map<String, dynamic>> familyMembers = [];
  bool _isLoading = true;
  int? currentUserId;

  List<Map<String, dynamic>> pendingInvitations = [];
  
  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      _prefsService = await PreferencesService.getInstance();
      currentUserId = _prefsService?.getCurrentUserId();
      print('Family Panel - Current User ID: $currentUserId');
      await _loadFamilyMembers();
    } catch (e) {
      print('Family Panel - Error in _initServices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFamilyMembers() async {
    try {
      if (currentUserId != null) {
        print('Family Panel - Loading family members for user: $currentUserId');
        List<Map<String, dynamic>> members = await _dbHelper.getFamilyMembers(currentUserId!);
        List<Map<String, dynamic>> invitations = await _dbHelper.getPendingInvitations(currentUserId!);
        print('Family Panel - Found ${members.length} family members and ${invitations.length} pending invitations');
        setState(() {
          familyMembers = members;
          pendingInvitations = invitations;
          _isLoading = false;
        });
      } else {
        print('Family Panel - No current user ID found');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Family Panel - Error loading family members: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helpers to map between localized labels and stable relation codes
  String _relationCodeFromLabel(LocalizationService loc, String label) {
    final mapping = {
      loc.getString('family_relation_spouse'): 'spouse',
      loc.getString('family_relation_child'): 'child',
      loc.getString('family_relation_father'): 'father',
      loc.getString('family_relation_mother'): 'mother',
      loc.getString('family_relation_sibling'): 'sibling',
      loc.getString('family_relation_grandmother'): 'grandmother',
      loc.getString('family_relation_grandfather'): 'grandfather',
      loc.getString('family_relation_other'): 'other',
    };
    return mapping[label] ?? _normalizeExistingStored(label);
  }

  String _normalizeExistingStored(String stored) {
    // If stored looks like a code already or legacy TR/EN label, map to code
    final s = stored.trim();
    const allowed = {
      'father','mother','child','spouse','sibling','grandfather','grandmother','grandchild','parent','grandparent','other'
    };
    if (allowed.contains(s)) return s;
    // Legacy Turkish/English to code
    const legacy = {
      'Baba': 'father', 'Anne': 'mother', 'Çocuk': 'child', 'Eş': 'spouse', 'Kardeş': 'sibling', 'Büyükbaba': 'grandfather', 'Büyükanne': 'grandmother', 'Torun': 'grandchild', 'Aile Üyesi': 'other',
      'Father': 'father', 'Mother': 'mother', 'Child': 'child', 'Spouse': 'spouse', 'Sibling': 'sibling', 'Grandfather': 'grandfather', 'Grandmother': 'grandmother', 'Grandchild': 'grandchild', 'Parent': 'parent', 'Grandparent': 'grandparent', 'Other': 'other',
    };
    return legacy[s] ?? 'other';
  }

  String _relationLabelFromStored(LocalizationService loc, String? stored) {
    if (stored == null || stored.isEmpty) return loc.getString('family_relation_unknown');
    final code = _normalizeExistingStored(stored);
    switch (code) {
      case 'spouse': return loc.getString('family_relation_spouse');
      case 'child': return loc.getString('family_relation_child');
      case 'father': return loc.getString('family_relation_father');
      case 'mother': return loc.getString('family_relation_mother');
      case 'sibling': return loc.getString('family_relation_sibling');
      case 'grandmother': return loc.getString('family_relation_grandmother');
      case 'grandfather': return loc.getString('family_relation_grandfather');
      case 'grandchild': return loc.getString('family_relation_grandchild');
      case 'parent': return loc.getString('family_relation_parent');
      case 'grandparent': return loc.getString('family_relation_grandparent');
      default: return loc.getString('family_relation_other');
    }
  }

  Future<void> _addFamilyMember() async {
    // İki seçenek sun: Manuel ekleme veya Gerçek kullanıcı davet etme
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizationService.getString('family_add_member')),
        content: Text(localizationService.getString('family_add_member_question')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: Text(localizationService.getString('family_add_manual_entry')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'invite'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
            child: Text(localizationService.getString('family_invite_real_user'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (choice == 'manual') {
      await _addManualFamilyMember();
    } else if (choice == 'invite') {
      await _inviteRealUser();
    }
  }

  Future<void> _addManualFamilyMember() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddFamilyMemberDialog(),
    );

    if (result != null && currentUserId != null) {
      result['user_id'] = currentUserId;
      result['is_real_user'] = false;
      // Normalize relation to code before saving
      final loc = Provider.of<LocalizationService>(context, listen: false);
      result['relation'] = _relationCodeFromLabel(loc, result['relation']);
      await _dbHelper.insertFamilyMember(result);
      await _loadFamilyMembers();
      
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getStringWithParams('family_member_added', {'name': result['name']})),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _inviteRealUser() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _InviteUserDialog(),
    );

    if (result != null && currentUserId != null) {
      // Kullanıcıyı telefon numarası ile ara
  String phone = result['phone'];
  String relationCode = _relationCodeFromLabel(Provider.of<LocalizationService>(context, listen: false), result['relation']);
      
      try {
        Map<String, dynamic>? targetUser = await _dbHelper.findUserByPhone(phone);
        
        if (targetUser != null) {
          // Davet gönder
          await _dbHelper.sendFamilyInvitation({
            'from_user_id': currentUserId,
            'to_user_id': targetUser['id'],
            'relation': relationCode,
            'message': result['message'],
          });
          
          final loc = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getStringWithParams('family_invite_sent', {'name': targetUser['name']})),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final loc = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getString('family_invite_user_not_found')),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getStringWithParams('family_invite_error', {'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(currentRoute: '/family_panel'),
      appBar: AppBar(
  title: Text(localizationService.getString('family_health_panel')),
        backgroundColor: const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addFamilyMember,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53E3E)))
        : familyMembers.isEmpty 
          ? _buildEmptyState()
          : _buildFamilyList(),
    );
  }

  Widget _buildEmptyState() {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            localizationService.getString('family_empty_title'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizationService.getString('family_empty_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addFamilyMember,
            icon: const Icon(Icons.person_add),
            label: Text(localizationService.getString('family_add_first_member')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList() {
    final localizationService = Provider.of<LocalizationService>(context, listen: false); // for potential future use
    return RefreshIndicator(
      onRefresh: _loadFamilyMembers,
      color: const Color(0xFFE53E3E),
      child: CustomScrollView(
        slivers: [
          // Bekleyen davetler
          if (pendingInvitations.isNotEmpty) 
            SliverToBoxAdapter(child: _buildPendingInvitations()),
          
          // Aile üyeleri listesi
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = familyMembers[index];
                  return _buildFamilyMemberCard(member);
                },
                childCount: familyMembers.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInvitations() {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.notifications_active, color: Colors.orange[700], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                localizationService.getStringWithParams('family_pending_invitations', {'count': pendingInvitations.length.toString()}),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...pendingInvitations.map((invitation) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Icon(Icons.person, color: Colors.orange[700]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invitation['from_user_name'] ?? localizationService.getString('family_unknown_user'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                localizationService.getStringWithParams('family_invited_as_relation', {'relation': _relationLabelFromStored(localizationService, invitation['relation'])}),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (invitation['message'] != null)
                                Text(
                                  invitation['message'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _respondToInvitation(invitation['id'], 'rejected'),
                          icon: const Icon(Icons.close, size: 16),
                          label: Text(localizationService.getString('family_decline')),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _respondToInvitation(invitation['id'], 'accepted'),
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(localizationService.getString('family_accept')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )).toList(),
        ],
      ),
    );
  }

  Future<void> _respondToInvitation(int invitationId, String response) async {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    try {
      await _dbHelper.respondToInvitation(invitationId, response);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
      response == 'accepted'
        ? localizationService.getString('family_invite_accepted')
        : localizationService.getString('family_invite_rejected'),
          ),
          backgroundColor: response == 'accepted' ? Colors.green : Colors.orange,
        ),
      );
      
      await _loadFamilyMembers(); // Listeyi yenile
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizationService.getStringWithParams('family_invite_response_error', {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFamilyMemberCard(Map<String, dynamic> member) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE53E3E).withOpacity(0.1),
                  child: Text(
                    member['gender'] == localizationService.getString('family_gender_female') ? '👩' : '👨',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'] ?? localizationService.getString('family_name_unknown'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.family_restroom, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _relationLabelFromStored(localizationService, member['relation']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${member['age'] ?? 0} ${localizationService.getString('family_age_suffix')}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editFamilyMember(member);
                    } else if (value == 'delete') {
                      _deleteFamilyMember(member);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit, size: 18),
                        const SizedBox(width: 8),
                        Text(localizationService.getString('family_edit')),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(localizationService.getString('family_delete'), style: const TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizationService.getString('family_hemogram_info'),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editFamilyMember(Map<String, dynamic> member) async {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddFamilyMemberDialog(member: member),
    );

    if (result != null) {
      // Normalize relation to code before saving
      result['relation'] = _relationCodeFromLabel(localizationService, result['relation']);
      await _dbHelper.updateFamilyMember(member['id'], result);
      await _loadFamilyMembers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizationService.getString('family_member_updated')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteFamilyMember(Map<String, dynamic> member) async {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizationService.getString('family_member_delete_title')),
        content: Text(localizationService.getStringWithParams('family_member_delete_confirm', {'name': member['name']})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizationService.getString('family_cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localizationService.getString('family_delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteFamilyMember(member['id']);
      await _loadFamilyMembers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizationService.getStringWithParams('family_member_deleted', {'name': member['name']})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _AddFamilyMemberDialog extends StatefulWidget {
  final Map<String, dynamic>? member;

  const _AddFamilyMemberDialog({this.member});

  @override
  State<_AddFamilyMemberDialog> createState() => _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends State<_AddFamilyMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late String _gender;
  late String _relation;

  String _normalizeExistingStored(String stored) {
    final s = stored.trim();
    const allowed = {
      'father','mother','child','spouse','sibling','grandfather','grandmother','grandchild','parent','grandparent','other'
    };
    if (allowed.contains(s)) return s;
    const legacy = {
      'Baba': 'father', 'Anne': 'mother', 'Çocuk': 'child', 'Eş': 'spouse', 'Kardeş': 'sibling', 'Büyükbaba': 'grandfather', 'Büyükanne': 'grandmother', 'Torun': 'grandchild', 'Aile Üyesi': 'other',
      'Father': 'father', 'Mother': 'mother', 'Child': 'child', 'Spouse': 'spouse', 'Sibling': 'sibling', 'Grandfather': 'grandfather', 'Grandmother': 'grandmother', 'Grandchild': 'grandchild', 'Parent': 'parent', 'Grandparent': 'grandparent', 'Other': 'other',
    };
    return legacy[s] ?? 'other';
  }

  String _labelFromStored(LocalizationService loc, String? stored) {
    if (stored == null || stored.isEmpty) return loc.getString('family_relation_spouse');
    final code = _normalizeExistingStored(stored);
    switch (code) {
      case 'spouse': return loc.getString('family_relation_spouse');
      case 'child': return loc.getString('family_relation_child');
      case 'father': return loc.getString('family_relation_father');
      case 'mother': return loc.getString('family_relation_mother');
      case 'sibling': return loc.getString('family_relation_sibling');
      case 'grandmother': return loc.getString('family_relation_grandmother');
      case 'grandfather': return loc.getString('family_relation_grandfather');
      case 'grandchild': return loc.getString('family_relation_grandchild');
      case 'parent': return loc.getString('family_relation_parent');
      case 'grandparent': return loc.getString('family_relation_grandparent');
      default: return loc.getString('family_relation_other');
    }
  }

  List<String> _relationOptions(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return [
      loc.getString('family_relation_spouse'),
      loc.getString('family_relation_child'),
      loc.getString('family_relation_father'),
      loc.getString('family_relation_mother'),
      loc.getString('family_relation_sibling'),
      loc.getString('family_relation_grandmother'),
      loc.getString('family_relation_grandfather'),
      loc.getString('family_relation_other'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?['name'] ?? '');
    _ageController = TextEditingController(text: widget.member?['age']?.toString() ?? '');
    final loc = LocalizationService();
    _gender = widget.member?['gender'] ?? loc.getString('family_gender_male');
    _relation = _labelFromStored(loc, widget.member?['relation']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Builder(builder: (context){
        final loc = Provider.of<LocalizationService>(context, listen: false);
        return Text(widget.member == null ? loc.getString('family_add_member') : loc.getString('family_member_delete_title'));
      }),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getString('family_name_label'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Provider.of<LocalizationService>(context, listen: false).getString('family_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getString('family_age_label'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Provider.of<LocalizationService>(context, listen: false).getString('family_age_required');
                  }
                  if (int.tryParse(value) == null) {
                    return Provider.of<LocalizationService>(context, listen: false).getString('family_age_invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getString('family_gender_label'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  Provider.of<LocalizationService>(context, listen: false).getString('family_gender_male'),
                  Provider.of<LocalizationService>(context, listen: false).getString('family_gender_female'),
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _relation,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getString('family_relation_label'),
                  border: const OutlineInputBorder(),
                ),
                items: _relationOptions(context).map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _relation = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Builder(builder: (context){return Text(Provider.of<LocalizationService>(context, listen:false).getString('family_cancel'));}),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'age': int.parse(_ageController.text),
                'gender': _gender,
                'relation': _relation,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
          child: Builder(builder: (context){
            final loc = Provider.of<LocalizationService>(context, listen:false);
            return Text(
              widget.member == null ? loc.getString('family_add_action') : loc.getString('family_update_action'),
              style: const TextStyle(color: Colors.white),
            );
          }),
        ),
      ],
    );
  }
}

class _InviteUserDialog extends StatefulWidget {
  @override
  State<_InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<_InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _messageController;
  late String _relation;

  List<String> _relationOptions(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return [
      loc.getString('family_relation_spouse'),
      loc.getString('family_relation_child'),
      loc.getString('family_relation_father'),
      loc.getString('family_relation_mother'),
      loc.getString('family_relation_sibling'),
      loc.getString('family_relation_grandmother'),
      loc.getString('family_relation_grandfather'),
      loc.getString('family_relation_other'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _messageController = TextEditingController(text: Provider.of<LocalizationService>(context, listen: false).getString('family_default_invite_message'));
    _relation = Provider.of<LocalizationService>(context, listen: false).getString('family_relation_spouse');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add, color: const Color(0xFFE53E3E)),
          const SizedBox(width: 8),
          Builder(builder: (context){return Text(Provider.of<LocalizationService>(context, listen:false).getString('family_invite_real_user'));}),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Provider.of<LocalizationService>(context, listen:false).getString('family_invite_info'),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen:false).getString('family_phone_label'),
                  hintText: Provider.of<LocalizationService>(context, listen:false).getString('family_phone_hint'),
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Provider.of<LocalizationService>(context, listen:false).getString('family_phone_required');
                  }
                  if (value.length < 10) {
                    return Provider.of<LocalizationService>(context, listen:false).getString('family_phone_invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _relation,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen:false).getString('family_relation_label'),
                  prefixIcon: const Icon(Icons.family_restroom),
                  border: const OutlineInputBorder(),
                ),
                items: _relationOptions(context).map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _relation = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen:false).getString('family_invite_message_label'),
                  prefixIcon: const Icon(Icons.message),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Provider.of<LocalizationService>(context, listen:false).getString('family_invite_message_required');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Builder(builder: (context){return Text(Provider.of<LocalizationService>(context, listen:false).getString('family_cancel'));}),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'phone': _phoneController.text.trim(),
                'relation': _relation,
                'message': _messageController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
          child: Builder(builder: (context){return Text(
            Provider.of<LocalizationService>(context, listen:false).getString('family_send_invite'),
            style: const TextStyle(color: Colors.white),
          );}),
        ),
      ],
    );
  }
}