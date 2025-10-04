
/// Family member roles and permissions system
enum FamilyRole {
  owner,     // Full access to own data + manage family
  guardian,  // Full access to managed members + limited own data
  viewer,    // Read-only access to shared data
  connected, // Bidirectional sharing with specific permissions
}

enum PermissionType {
  viewHemogramResults,
  viewTrends,
  viewSummaryOnly,
  addReminders,
  viewReminders,
  viewWaterIntake,
  addWaterIntake,
  viewMedications,
  manageMedications,
  inviteMembers,
  manageFamily,
}

class FamilyPermissions {
  final Set<PermissionType> permissions = {};
  final FamilyRole role;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> constraints;

  FamilyPermissions({
    required this.role,
    required this.grantedAt,
    this.expiresAt,
    this.constraints = const {},
  }) {
    _initializeDefaultPermissions();
  }

  void _initializeDefaultPermissions() {
    switch (role) {
      case FamilyRole.owner:
        permissions.addAll(PermissionType.values); // Full access
        break;
      case FamilyRole.guardian:
        permissions.addAll([
          PermissionType.viewHemogramResults,
          PermissionType.viewTrends,
          PermissionType.addReminders,
          PermissionType.viewReminders,
          PermissionType.viewWaterIntake,
          PermissionType.addWaterIntake,
          PermissionType.viewMedications,
          PermissionType.manageMedications,
          PermissionType.inviteMembers,
        ]);
        break;
      case FamilyRole.viewer:
        permissions.addAll([
          PermissionType.viewSummaryOnly,
          PermissionType.viewWaterIntake,
        ]);
        break;
      case FamilyRole.connected:
        permissions.addAll([
          PermissionType.viewHemogramResults,
          PermissionType.viewTrends,
          PermissionType.viewReminders,
          PermissionType.viewWaterIntake,
        ]);
        break;
    }
  }

  bool hasPermission(PermissionType permission) {
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false; // Permissions expired
    }
    return permissions.contains(permission);
  }

  bool canViewFullHemogramData() {
    return hasPermission(PermissionType.viewHemogramResults);
  }

  bool canViewSummaryOnly() {
    return hasPermission(PermissionType.viewSummaryOnly) && 
           !hasPermission(PermissionType.viewHemogramResults);
  }

  bool canManageFamily() {
    return hasPermission(PermissionType.manageFamily);
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'permissions': permissions.map((p) => p.name).toList(),
      'granted_at': grantedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'constraints': constraints,
    };
  }

  static FamilyPermissions fromJson(Map<String, dynamic> json) {
    final role = FamilyRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => FamilyRole.viewer,
    );
    
    final permissions = FamilyPermissions(
      role: role,
      grantedAt: DateTime.parse(json['granted_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      constraints: Map<String, dynamic>.from(json['constraints'] ?? {}),
    );
    
    // Override with stored permissions if available
    if (json['permissions'] is List) {
      permissions.permissions.clear();
      for (final permName in json['permissions']) {
        final perm = PermissionType.values.where((p) => p.name == permName).firstOrNull;
        if (perm != null) {
          permissions.permissions.add(perm);
        }
      }
    }
    
    return permissions;
  }
}

/// Extended family member model with role and permissions
class FamilyMemberWithPermissions {
  final int id;
  final int userId;
  final String name;
  final String? phone;
  final String? email;
  final int? connectedUserId;
  final FamilyPermissions permissions;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'blocked'
  final Map<String, dynamic> metadata;

  FamilyMemberWithPermissions({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.connectedUserId,
    required this.permissions,
    required this.createdAt,
    required this.status,
    this.metadata = const {},
  });

  bool get isActive => status == 'accepted';
  bool get isPending => status == 'pending';
  bool get isBlocked => status == 'blocked';

  String getDisplayRole(String Function(String) localizer) {
    switch (permissions.role) {
      case FamilyRole.owner:
        return localizer('family_role_owner');
      case FamilyRole.guardian:
        return localizer('family_role_guardian');
      case FamilyRole.viewer:
        return localizer('family_role_viewer');
      case FamilyRole.connected:
        return localizer('family_role_connected');
    }
  }

  List<String> getPermissionSummary(String Function(String) localizer) {
    final summary = <String>[];
    
    if (permissions.canViewFullHemogramData()) {
      summary.add(localizer('permission_view_full_results'));
    } else if (permissions.canViewSummaryOnly()) {
      summary.add(localizer('permission_view_summary_only'));
    }
    
    if (permissions.hasPermission(PermissionType.addReminders)) {
      summary.add(localizer('permission_manage_reminders'));
    }
    
    if (permissions.hasPermission(PermissionType.viewWaterIntake)) {
      summary.add(localizer('permission_view_water_intake'));
    }
    
    if (permissions.canManageFamily()) {
      summary.add(localizer('permission_manage_family'));
    }
    
    return summary;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'connected_user_id': connectedUserId,
      'permissions': permissions.toJson(),
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'metadata': metadata,
    };
  }

  static FamilyMemberWithPermissions fromJson(Map<String, dynamic> json) {
    return FamilyMemberWithPermissions(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      connectedUserId: json['connected_user_id'],
      permissions: FamilyPermissions.fromJson(json['permissions'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Create from legacy family member data
  static FamilyMemberWithPermissions fromLegacy(Map<String, dynamic> legacy) {
    // Default to viewer role for legacy members
    final permissions = FamilyPermissions(
      role: FamilyRole.viewer,
      grantedAt: DateTime.now(),
    );

    return FamilyMemberWithPermissions(
      id: legacy['id'] ?? 0,
      userId: legacy['user_id'] ?? 0,
      name: legacy['name'] ?? '',
      phone: legacy['phone'],
      email: legacy['email'],
      connectedUserId: legacy['connected_user_id'],
      permissions: permissions,
      createdAt: DateTime.tryParse(legacy['created_at'] ?? '') ?? DateTime.now(),
      status: legacy['status'] ?? 'accepted',
    );
  }
}

/// Family data sharing policies
class FamilyDataSharingPolicy {
  static const String defaultPolicy = '''
Family Data Sharing Policy:

• Summary view: Recent test results overview, trend indicators
• Full view: Complete hemogram details, historical data, analysis
• Reminders: Can view and add health reminders for family members
• Water intake: Track daily water consumption together
• Medications: View and manage medication schedules (with permission)

Your data privacy:
• You control what you share with each family member
• Data is stored locally on your device
• No data is sent to external servers
• You can revoke access at any time

Family member roles:
• Owner: Full access to their own data + family management
• Guardian: Can manage specific family members (e.g., children)
• Viewer: Read-only access to shared summaries
• Connected: Mutual sharing with agreed permissions
''';

  static String getPolicyForRole(FamilyRole role, String Function(String) localizer) {
    switch (role) {
      case FamilyRole.owner:
        return localizer('family_policy_owner');
      case FamilyRole.guardian:
        return localizer('family_policy_guardian');
      case FamilyRole.viewer:
        return localizer('family_policy_viewer');
      case FamilyRole.connected:
        return localizer('family_policy_connected');
    }
  }

  static List<PermissionType> getRecommendedPermissions(FamilyRole role, String relationship) {
    final base = <PermissionType>[];
    
    switch (role) {
      case FamilyRole.guardian:
        if (relationship == 'child' || relationship == 'elderly_parent') {
          base.addAll([
            PermissionType.viewHemogramResults,
            PermissionType.addReminders,
            PermissionType.viewMedications,
            PermissionType.manageMedications,
            PermissionType.addWaterIntake,
          ]);
        }
        break;
      case FamilyRole.connected:
        base.addAll([
          PermissionType.viewTrends,
          PermissionType.viewSummaryOnly,
          PermissionType.viewWaterIntake,
        ]);
        break;
      case FamilyRole.viewer:
        base.addAll([
          PermissionType.viewSummaryOnly,
        ]);
        break;
      case FamilyRole.owner:
        base.addAll(PermissionType.values);
        break;
    }
    
    return base;
  }
}