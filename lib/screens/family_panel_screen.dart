import 'package:flutter/material.dart';
import '../utils/color_compat.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/responsive_helper.dart';
import '../services/family_service.dart';
import '../widgets/labubu_avatar.dart';
import '../services/cache_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class FamilyPanelScreen extends StatefulWidget {
  const FamilyPanelScreen({Key? key}) : super(key: key);

  @override
  State<FamilyPanelScreen> createState() => _FamilyPanelScreenState();
}

class _FamilyPanelScreenState extends State<FamilyPanelScreen> {
  PreferencesService? _prefsService;
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FamilyService _familyService = FamilyService();
  List<Map<String, dynamic>> familyMembers = [];
  List<Map<String, dynamic>> filteredMembers = [];
  List<Map<String, dynamic>> pendingInvitations = [];
  bool _isLoading = true;
  int? currentUserId;

  // UI state: search/filter/sort
  final TextEditingController _searchController = TextEditingController();
  String _relationFilter = 'all';
  String _sortKey = 'name'; // name|age
  bool _sortAsc = true;
  
  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      _prefsService = await PreferencesService.getInstance();
      final loggedIn = _prefsService?.isUserLoggedIn() ?? false;
      currentUserId = _prefsService?.getCurrentUserId();
      debugPrint('Family Panel - Current User ID: $currentUserId');
      if (!loggedIn || currentUserId == null) {
        if (!mounted) return;
        // Do not redirect anymore; show inline login prompt instead
        setState(() { _isLoading = false; });
      } else {
        await _loadFamilyMembers();
      }
    } catch (e) {
      debugPrint('Family Panel - Error in _initServices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFamilyMembers() async {
    try {
      if (currentUserId != null) {
        debugPrint('Family Panel - Loading family members for user: $currentUserId');
        List<Map<String, dynamic>> members = await _db.getFamilyMembers(currentUserId!);
        List<Map<String, dynamic>> invitations = await _db.getPendingInvitations(currentUserId!);
        debugPrint('Family Panel - Found ${members.length} family members and ${invitations.length} pending invitations');
        setState(() {
          familyMembers = members;
          filteredMembers = members;
          pendingInvitations = invitations;
          _isLoading = false;
        });
      } else {
        debugPrint('Family Panel - No current user ID found');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Family Panel - Error loading family members: $e');
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
    String asciiLower(String input) => input
        .toLowerCase()
        .replaceAll('\u015f', 's') // ş
        .replaceAll('\u015e', 's') // Ş
        .replaceAll('\u011f', 'g') // ğ
        .replaceAll('\u011e', 'g') // Ğ
        .replaceAll('\u00f6', 'o') // ö
        .replaceAll('\u00d6', 'o') // Ö
        .replaceAll('\u00fc', 'u') // ü
        .replaceAll('\u00dc', 'u') // Ü
        .replaceAll('\u0131', 'i') // ı
        .replaceAll('\u00e7', 'c') // ç
        .replaceAll('\u00c7', 'c'); // Ç
    final key = asciiLower(s);
    const map = {
      // Turkish labels (ASCII-normalized)
      'baba': 'father',
      'anne': 'mother',
      'cocuk': 'child',
      'es': 'spouse',
      'kardes': 'sibling',
      'buyukbaba': 'grandfather',
      'buyukanne': 'grandmother',
      'torun': 'grandchild',
      'aile uyesi': 'other',
      // English labels
      'father': 'father',
      'mother': 'mother',
      'child': 'child',
      'spouse': 'spouse',
      'sibling': 'sibling',
      'grandfather': 'grandfather',
      'grandmother': 'grandmother',
      'grandchild': 'grandchild',
      'parent': 'parent',
      'grandparent': 'grandparent',
      'other': 'other',
    };
    return map[key] ?? 'other';
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
    // Offer two options: manual entry or invite a real registered user
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
      
      // Clear cache before inserting
      final cache = HemoAICache();
      cache.clearFamilyMembers(currentUserId!);
      
      await _db.insertFamilyMember(result);
      
      // Force refresh
      await _loadFamilyMembers();
      
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.getStringWithParams('family_member_added', {'name': result['name']})),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
      // Find target user by phone number
  String phone = result['phone'];
  String relationCode = _relationCodeFromLabel(Provider.of<LocalizationService>(context, listen: false), result['relation']);
      
      try {
  Map<String, dynamic>? targetUser = await _db.findUserByPhone(phone);
        
        if (targetUser != null) {
          // Send invitation
          await _db.sendFamilyInvitation({
            'from_user_id': currentUserId,
            'to_user_id': targetUser['id'],
            'relation': relationCode,
            'message': result['message'],
          });
          
          final loc = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.getStringWithParams('family_invite_sent', {'name': targetUser['name']})),
              backgroundColor: Theme.of(context).colorScheme.primary,
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const AppDrawer(currentRoute: '/family_panel'),
      appBar: AppBar(
        title: Text(localizationService.getString('family_health_panel')),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: cs.onPrimary),
            onPressed: _addFamilyMember,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53E3E)))
        : (currentUserId == null)
          ? _buildLoginPrompt()
          : (familyMembers.isEmpty 
            ? _buildEmptyState()
            : _buildFamilyContent()),
    );
  }

  Widget _buildLoginPrompt() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            color: cs.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.group, color: cs.onPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.getString('family_login_required_title'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.getString('family_login_required_desc'),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: .75)),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/login'),
                      icon: const Icon(Icons.login),
                      label: Text(loc.getString('go_to_login')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            localizationService.getString('family_empty_title'),
            style: TextStyle(
              fontSize: 18,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizationService.getString('family_empty_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addFamilyMember,
            icon: const Icon(Icons.person_add),
            label: Text(localizationService.getString('family_add_first_member')),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
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
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return RefreshIndicator(
      onRefresh: _loadFamilyMembers,
      color: const Color(0xFFE53E3E),
      child: CustomScrollView(
        slivers: [
          // Pending invitations
          if (pendingInvitations.isNotEmpty) 
            SliverToBoxAdapter(child: _buildPendingInvitations()),

          // Search + filters bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildSearchAndFilters(loc),
            ),
          ),

          // Family members grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.getGridColumns(context),
                mainAxisSpacing: ResponsiveHelper.getCardSpacing(context),
                crossAxisSpacing: ResponsiveHelper.getCardSpacing(context),
                childAspectRatio: ResponsiveHelper.isMobile(context) ? 16/10 : 16/9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = filteredMembers[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/family_member_detail', arguments: member),
                    child: _FamilyMemberCard(
                    member: member,
                    onEdit: () => _editFamilyMember(member),
                    onDelete: () => _deleteFamilyMember(member),
                    relationLabel: _relationLabelFromStored(loc, member['relation']),
                    ),
                  );
                },
                childCount: filteredMembers.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyContent() {
    // If 3+ members, show a simple family tree above the list
    if (familyMembers.length < 3) {
      return _buildFamilyList();
    }
    final cs = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString('family_tree_title') == 'family_tree_title'
                      ? 'Family Tree'
                      : Provider.of<LocalizationService>(context, listen: false).getString('family_tree_title'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 12),
                _buildSimpleTree(cs),
                const SizedBox(height: 8),
                Divider(color: cs.outlineVariant),
              ],
            ),
          ),
        ),
        // Reuse existing list below
        SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(child: SizedBox(height: 0, child: const Divider())),
        SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(child: _buildSearchAndFilters(Provider.of<LocalizationService>(context, listen: false))),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.getGridColumns(context),
              mainAxisSpacing: ResponsiveHelper.getCardSpacing(context),
              crossAxisSpacing: ResponsiveHelper.getCardSpacing(context),
              childAspectRatio: ResponsiveHelper.isMobile(context) ? 16 / 10 : 16 / 9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final member = filteredMembers[index];
                return _FamilyMemberCard(
                  member: member,
                  onEdit: () => _editFamilyMember(member),
                  onDelete: () => _deleteFamilyMember(member),
                  relationLabel: _relationLabelFromStored(Provider.of<LocalizationService>(context, listen: false), member['relation']),
                );
              },
              childCount: filteredMembers.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTree(ColorScheme cs) {
    // naive grouping by relation
    final parents = familyMembers.where((m) => (m['relation'] ?? '').toString().toLowerCase().contains('parent') || (m['relation'] ?? '').toString().toLowerCase().contains('father') || (m['relation'] ?? '').toString().toLowerCase().contains('mother')).toList();
    final children = familyMembers.where((m) => (m['relation'] ?? '').toString().toLowerCase().contains('child')).toList();
    final others = familyMembers.where((m) => !parents.contains(m) && !children.contains(m)).toList();

    Widget line() => Container(height: 16, width: 2, color: cs.outlineVariant);

    Widget node(Map<String, dynamic> m) => Column(
      children: [
        LabubuAvatar(
          seed: (m['name'] ?? '?')?.toString() ?? '',
          size: 40,
        ),
        const SizedBox(height: 4),
        Text((m['name'] ?? '') as String, style: TextStyle(fontSize: 12, color: cs.onSurface)),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          // Root connection text
          if (familyMembers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Connections', style: TextStyle(color: cs.onSurface.withValues(alpha: .7))),
            ),
          // Parents row
          if (parents.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: parents.map((m) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: node(m))).toList(),
            ),
          if (parents.isNotEmpty) line(),
          // Self + others row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: (others.isNotEmpty ? others : familyMembers).map((m) => node(m)).toList(),
          ),
          line(),
          // Children row
          if (children.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: children.map((m) => node(m)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(LocalizationService loc) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: loc.getString('family_search_hint'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _relationFilter,
                  onChanged: (v) { setState(() { _relationFilter = v!; _applyFilters(); }); },
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(loc.getString('family_filter_all'))),
                    DropdownMenuItem(value: 'spouse', child: Text(loc.getString('family_relation_spouse'))),
                    DropdownMenuItem(value: 'child', child: Text(loc.getString('family_relation_child'))),
                    DropdownMenuItem(value: 'father', child: Text(loc.getString('family_relation_father'))),
                    DropdownMenuItem(value: 'mother', child: Text(loc.getString('family_relation_mother'))),
                    DropdownMenuItem(value: 'sibling', child: Text(loc.getString('family_relation_sibling'))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _sortKey,
                  onChanged: (v) { setState(() { _sortKey = v!; _applyFilters(); }); },
                  items: [
                    DropdownMenuItem(value: 'name', child: Text(loc.getString('family_sort_name'))),
                    DropdownMenuItem(value: 'age', child: Text(loc.getString('family_sort_age'))),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: loc.getString('family_sort_toggle'),
              onPressed: () { setState(() { _sortAsc = !_sortAsc; _applyFilters(); }); },
              icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
            ),
          ],
        ),
      ],
    );
  }

  void _applyFilters() {
    final term = _searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> list = List.of(familyMembers);
    if (term.isNotEmpty) {
      list = list.where((m) => (m['name'] ?? '').toString().toLowerCase().contains(term)).toList();
    }
    if (_relationFilter != 'all') {
      list = list.where((m) => _normalizeExistingStored((m['relation'] ?? '').toString()) == _relationFilter).toList();
    }
    list.sort((a, b) {
      int cmp;
      if (_sortKey == 'age') {
        cmp = ((a['age'] ?? 0) as int).compareTo((b['age'] ?? 0) as int);
      } else {
        cmp = (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase());
      }
      return _sortAsc ? cmp : -cmp;
    });
    setState(() { filteredMembers = list; });
  }

  Widget _buildPendingInvitations() {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.tertiaryContainer.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.notifications_active, color: cs.onTertiaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                localizationService.getStringWithParams('family_pending_invitations', {'count': pendingInvitations.length.toString()}),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onTertiaryContainer,
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
                            backgroundColor: Theme.of(context).colorScheme.primary,
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
      await _db.respondToInvitation(invitationId, response);
      
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
      
  await _loadFamilyMembers(); // Refresh the list
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizationService.getStringWithParams('family_invite_response_error', {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Note: legacy _buildFamilyMemberCard removed; grid now uses _FamilyMemberCard directly.

  Future<void> _editFamilyMember(Map<String, dynamic> member) async {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddFamilyMemberDialog(member: member),
    );

    if (result != null) {
      // Normalize relation to code before saving
      result['relation'] = _relationCodeFromLabel(localizationService, result['relation']);
  await _db.updateFamilyMember(member['id'], result);
      await _loadFamilyMembers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizationService.getString('family_member_updated')),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
  await _db.deleteFamilyMember(member['id']);
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
    String asciiLower(String input) => input
        .toLowerCase()
        .replaceAll('\u015f', 's') // ş
        .replaceAll('\u015e', 's') // Ş
        .replaceAll('\u011f', 'g') // ğ
        .replaceAll('\u011e', 'g') // Ğ
        .replaceAll('\u00f6', 'o') // ö
        .replaceAll('\u00d6', 'o') // Ö
        .replaceAll('\u00fc', 'u') // ü
        .replaceAll('\u00dc', 'u') // Ü
        .replaceAll('\u0131', 'i') // ı
        .replaceAll('\u00e7', 'c') // ç
        .replaceAll('\u00c7', 'c'); // Ç
    final key = asciiLower(s);
    const map = {
      // Turkish labels (ASCII-normalized)
      'baba': 'father',
      'anne': 'mother',
      'cocuk': 'child',
      'es': 'spouse',
      'kardes': 'sibling',
      'buyukbaba': 'grandfather',
      'buyukanne': 'grandmother',
      'torun': 'grandchild',
      'aile uyesi': 'other',
      // English labels
      'father': 'father',
      'mother': 'mother',
      'child': 'child',
      'spouse': 'spouse',
      'sibling': 'sibling',
      'grandfather': 'grandfather',
      'grandmother': 'grandmother',
      'grandchild': 'grandchild',
      'parent': 'parent',
      'grandparent': 'grandparent',
      'other': 'other',
    };
    return map[key] ?? 'other';
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
    final cs = Theme.of(context).colorScheme;
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
                initialValue: _gender,
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
                initialValue: _relation,
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
          style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
          child: Builder(builder: (context){
            final loc = Provider.of<LocalizationService>(context, listen:false);
            return Text(
              widget.member == null ? loc.getString('family_add_action') : loc.getString('family_update_action'),
              style: TextStyle(color: cs.onPrimary),
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

  Future<void> _selectFromContacts(BuildContext context) async {
    try {
      // Request contacts permission
      final permission = await Permission.contacts.request();
      if (!permission.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission is required to select a contact'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final flutterContactsGranted = await FlutterContacts.requestPermission(readonly: true);
      if (!flutterContactsGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission denied'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get contacts
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (!context.mounted) return;

      // Show contact picker
      final selectedContact = await showDialog<Contact>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Contact'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final phoneNumber = contact.phones.isNotEmpty
                    ? contact.phones.first.number
                    : 'No phone';
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(contact.displayName),
                  subtitle: Text(phoneNumber),
                  onTap: () => Navigator.pop(context, contact),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedContact != null && selectedContact.phones.isNotEmpty) {
        final phoneValue = selectedContact.phones.first.number;
        final phoneNumber = phoneValue
            .replaceAll(RegExp(r'[^\d+]'), '')
            .trim();
        setState(() {
          _phoneController.text = phoneNumber;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting contact: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add, color: cs.primary),
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
                  color: cs.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.secondaryContainer.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: cs.onSecondaryContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Provider.of<LocalizationService>(context, listen:false).getString('family_invite_info'),
                        style: TextStyle(color: cs.onSecondaryContainer, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
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
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.contacts),
                    tooltip: 'Select from contacts',
                    onPressed: () => _selectFromContacts(context),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _relation,
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
          style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
          child: Builder(builder: (context){return Text(
            Provider.of<LocalizationService>(context, listen:false).getString('family_send_invite'),
            style: TextStyle(color: cs.onPrimary),
          );}),
        ),
      ],
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String relationLabel;

  const _FamilyMemberCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
    required this.relationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final connectedUserId = member['connected_user_id'];
    final isConnected = connectedUserId != null && connectedUserId is int;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          if (isConnected) {
            // Navigate to member's health dashboard
            Navigator.of(context).pushNamed(
              '/analysis',
              arguments: {'family_member_id': connectedUserId},
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.getString('family_not_connected'))),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 6,
              color: cs.primary,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabubuAvatar(
                    seed: member['name']?.toString() ?? '',
                    size: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name'] ?? loc.getString('family_name_unknown'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.family_restroom, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                relationLabel,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.cake, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('${member['age'] ?? 0} ${loc.getString('family_age_suffix')}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'delete') onDelete(); },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width:8), Text(loc.getString('family_edit'))])),
                      PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, color: Colors.red, size: 18), const SizedBox(width:8), Text(loc.getString('family_delete'), style: const TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (isConnected)
              FutureBuilder<Map<String, dynamic>?>(
                future: FamilyService().getLatestHemogramForConnected(connectedUserId as int),
                builder: (context, snapshot) {
                  final hasData = snapshot.hasData && snapshot.data != null;
                  if (!hasData) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: cs.onSecondaryContainer, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.getString('family_no_test_data_yet'),
                                style: TextStyle(color: cs.onSecondaryContainer, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final test = snapshot.data!;
                  final testDate = DateTime.parse(test['test_date'] ?? DateTime.now().toIso8601String());
                  final daysAgo = DateTime.now().difference(testDate).inDays;
                  
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primaryContainer.withValues(alpha: 0.3), cs.primary.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.health_and_safety, color: cs.primary, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loc.getString('family_latest_test'),
                                  style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
                                ),
                              ),
                              Chip(
                                label: Text('${daysAgo}d ${loc.getString('ago')}', style: const TextStyle(fontSize: 10)),
                                backgroundColor: cs.surfaceContainerHighest,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: _buildHealthMetric(
                                  context,
                                  Icons.bloodtype,
                                  'Hemoglobin',
                                  test['hemoglobin']?.toStringAsFixed(1) ?? 'N/A',
                                  Colors.red.shade400,
                                ),
                              ),
                              Container(width: 1, height: 30, color: cs.outlineVariant),
                              Expanded(
                                child: _buildHealthMetric(
                                  context,
                                  Icons.bubble_chart,
                                  'Glucose',
                                  test['glucose']?.toStringAsFixed(1) ?? 'N/A',
                                  Colors.orange.shade400,
                                ),
                              ),
                              Container(width: 1, height: 30, color: cs.outlineVariant),
                              Expanded(
                                child: _buildHealthMetric(
                                  context,
                                  Icons.wb_sunny,
                                  'Vit D3',
                                  test['vitamin_d3']?.toStringAsFixed(0) ?? 'N/A',
                                  Colors.amber.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link_off, color: cs.onTertiaryContainer, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.getString('family_manual_entry_only'),
                          style: TextStyle(color: cs.onTertiaryContainer, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHealthMetric(BuildContext context, IconData icon, String label, String value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}