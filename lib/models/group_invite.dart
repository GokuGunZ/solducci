/// Group invitation model
/// Corresponds to 'group_invites' table in Supabase
class GroupInvite {
  final String id; // UUID
  final String groupId;
  final String inviterId; // User who sent the invite
  final String inviteeEmail;
  final String? inviteeId; // User who received (null if not registered yet)
  InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  DateTime? respondedAt;

  // Denormalized data for UI
  String? groupName;
  String? inviterNickname;

  GroupInvite({
    required this.id,
    required this.groupId,
    required this.inviterId,
    required this.inviteeEmail,
    this.inviteeId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    this.groupName,
    this.inviterNickname,
  });

  /// Create GroupInvite from Supabase map
  factory GroupInvite.fromMap(Map<String, dynamic> map) {
    return GroupInvite(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      inviterId: map['inviter_id'] as String,
      inviteeEmail: map['invitee_email'] as String,
      inviteeId: map['invitee_id'] as String?,
      status: InviteStatus.fromString(map['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'] as String)
          : null,
      // Denormalized fields (from JOINs)
      groupName: map['group_name'] as String?,
      inviterNickname: map['inviter_nickname'] as String?,
    );
  }

  /// Convert GroupInvite to Supabase map for insert
  Map<String, dynamic> toInsertMap() {
    return {
      'group_id': groupId,
      'inviter_id': inviterId,
      'invitee_email': inviteeEmail,
      'invitee_id': inviteeId,
    };
  }

  /// Convert to map for update (status change)
  Map<String, dynamic> toUpdateMap() {
    return {
      'status': status.value,
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  /// Check if invite is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if invite is pending
  bool get isPending => status == InviteStatus.pending && !isExpired;

  /// Check if invite is accepted
  bool get isAccepted => status == InviteStatus.accepted;

  /// Check if invite is rejected
  bool get isRejected => status == InviteStatus.rejected;

  /// Get display text for status
  String get statusDisplay {
    if (isExpired && status == InviteStatus.pending) {
      return 'Scaduto';
    }
    return status.label;
  }

  /// Get color for status
  String get statusColor {
    if (isExpired && status == InviteStatus.pending) {
      return 'grey';
    }
    switch (status) {
      case InviteStatus.pending:
        return 'orange';
      case InviteStatus.accepted:
        return 'green';
      case InviteStatus.rejected:
        return 'red';
      case InviteStatus.expired:
        return 'grey';
    }
  }

  @override
  String toString() {
    return 'GroupInvite(id: $id, group: $groupName, to: $inviteeEmail, status: ${status.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupInvite && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Status of a group invitation
enum InviteStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired');

  final String value;
  const InviteStatus(this.value);

  static InviteStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return InviteStatus.pending;
      case 'accepted':
        return InviteStatus.accepted;
      case 'rejected':
        return InviteStatus.rejected;
      case 'expired':
        return InviteStatus.expired;
      default:
        return InviteStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case InviteStatus.pending:
        return 'In Attesa';
      case InviteStatus.accepted:
        return 'Accettato';
      case InviteStatus.rejected:
        return 'Rifiutato';
      case InviteStatus.expired:
        return 'Scaduto';
    }
  }
}
