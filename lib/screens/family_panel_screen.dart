import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';

class FamilyPanelScreen extends StatefulWidget {
  const FamilyPanelScreen({Key? key}) : super(key: key);

  @override
  State<FamilyPanelScreen> createState() => _FamilyPanelScreenState();
}

class _FamilyPanelScreenState extends State<FamilyPanelScreen> {
  PreferencesService? _prefsService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
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

  Future<void> _addFamilyMember() async {
    // İki seçenek sun: Manuel ekleme veya Gerçek kullanıcı davet etme
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aile Üyesi Ekle'),
        content: const Text('Hangi yöntemi kullanmak istiyorsuniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: const Text('Manuel Bilgi Girişi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'invite'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
            child: const Text('Gerçek Kullanıcı Davet Et', style: TextStyle(color: Colors.white)),
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
      await _dbHelper.insertFamilyMember(result);
      await _loadFamilyMembers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['name']} aile paneline eklendi'),
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
      String relation = result['relation'];
      
      try {
        Map<String, dynamic>? targetUser = await _dbHelper.findUserByPhone(phone);
        
        if (targetUser != null) {
          // Davet gönder
          await _dbHelper.sendFamilyInvitation({
            'from_user_id': currentUserId,
            'to_user_id': targetUser['id'],
            'relation': relation,
            'message': result['message'],
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${targetUser['name']} kişisine davet gönderildi!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu telefon numarası ile kayıtlı kullanıcı bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Davet gönderilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Aile Sağlık Paneli'),
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
            'Henüz aile üyesi eklenmemiş',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aile üyelerinizi ekleyerek sağlık durumlarını\ntakip edebilirsiniz',
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
            label: const Text('İlk Aile Üyesini Ekle'),
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
                'Bekleyen Davetler (${pendingInvitations.length})',
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
                                invitation['from_user_name'] ?? 'Bilinmeyen Kullanıcı',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${invitation['relation'] ?? 'Aile Üyesi'} olarak davet etti',
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
                          label: const Text('Reddet'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _respondToInvitation(invitation['id'], 'accepted'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Kabul Et'),
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
    try {
      await _dbHelper.respondToInvitation(invitationId, response);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response == 'accepted' ? 'Davet kabul edildi!' : 'Davet reddedildi.',
          ),
          backgroundColor: response == 'accepted' ? Colors.green : Colors.orange,
        ),
      );
      
      await _loadFamilyMembers(); // Listeyi yenile
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yanıt gönderilirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFamilyMemberCard(Map<String, dynamic> member) {
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
                    member['gender'] == 'Kadın' ? '👩' : '👨',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'] ?? 'İsimsiz',
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
                            member['relation'] ?? 'Bilinmiyor',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${member['age'] ?? 0} yaş',
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
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
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
                      'Hemogram testleri henüz eklenmemiş. Test sonuçları eklemek için üyeye tıklayın.',
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddFamilyMemberDialog(member: member),
    );

    if (result != null) {
      await _dbHelper.updateFamilyMember(member['id'], result);
      await _loadFamilyMembers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aile üyesi güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteFamilyMember(Map<String, dynamic> member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aile Üyesini Sil'),
        content: Text('${member['name']} adlı aile üyesini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteFamilyMember(member['id']);
      await _loadFamilyMembers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member['name']} silindi'),
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
  String _gender = 'Erkek';
  String _relation = 'Eş';

  final List<String> _relations = [
    'Eş', 'Çocuk', 'Baba', 'Anne', 'Kardeş', 'Büyükanne', 'Büyükbaba', 'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?['name'] ?? '');
    _ageController = TextEditingController(text: widget.member?['age']?.toString() ?? '');
    _gender = widget.member?['gender'] ?? 'Erkek';
    _relation = widget.member?['relation'] ?? 'Eş';
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
      title: Text(widget.member == null ? 'Aile Üyesi Ekle' : 'Aile Üyesini Düzenle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Yaş',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yaş gerekli';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçerli bir yaş girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Cinsiyet',
                  border: OutlineInputBorder(),
                ),
                items: ['Erkek', 'Kadın'].map((String value) {
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
                decoration: const InputDecoration(
                  labelText: 'Yakınlık Derecesi',
                  border: OutlineInputBorder(),
                ),
                items: _relations.map((String value) {
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
          child: const Text('İptal'),
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
          child: Text(
            widget.member == null ? 'Ekle' : 'Güncelle',
            style: const TextStyle(color: Colors.white),
          ),
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
  String _relation = 'Eş';

  final List<String> _relations = [
    'Eş', 'Çocuk', 'Baba', 'Anne', 'Kardeş', 'Büyükanne', 'Büyükbaba', 'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _messageController = TextEditingController(text: 'Sizi aile sağlık panelime eklemek istiyorum.');
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
          const Text('Gerçek Kullanıcı Davet Et'),
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
                        'Bu kişi HemoAI uygulamasını kullanıyor olmalıdır. Davet gönderilecek ve onaylaması beklenecek.',
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
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  hintText: '5551234567',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefon numarası gerekli';
                  }
                  if (value.length < 10) {
                    return 'Geçerli bir telefon numarası girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _relation,
                decoration: const InputDecoration(
                  labelText: 'Yakınlık Derecesi',
                  prefixIcon: Icon(Icons.family_restroom),
                  border: OutlineInputBorder(),
                ),
                items: _relations.map((String value) {
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
                decoration: const InputDecoration(
                  labelText: 'Davet Mesajı',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Davet mesajı gerekli';
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
          child: const Text('İptal'),
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
          child: const Text(
            'Davet Gönder',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}