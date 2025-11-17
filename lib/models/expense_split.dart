/// Model representing a split of an expense among group members
class ExpenseSplit {
  final String id;
  final String expenseId;
  final String userId;
  final double amount;
  final bool isPaid;
  final DateTime createdAt;

  // Joined data from profiles table
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;

  ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    required this.isPaid,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
  });

  /// Create ExpenseSplit from Supabase map
  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      id: map['id'].toString(), // Handle both int and String
      expenseId: map['expense_id'].toString(), // Handle both int and String
      userId: map['user_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      isPaid: map['is_paid'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      userName: map['user_name'] as String?,
      userEmail: map['user_email'] as String?,
      userAvatarUrl: map['user_avatar_url'] as String?,
    );
  }

  /// Convert to map for Supabase insert/update
  Map<String, dynamic> toMap() {
    return {
      'expense_id': expenseId,
      'user_id': userId,
      'amount': amount,
      'is_paid': isPaid,
    };
  }

  /// Create a copy with updated fields
  ExpenseSplit copyWith({
    String? id,
    String? expenseId,
    String? userId,
    double? amount,
    bool? isPaid,
    DateTime? createdAt,
    String? userName,
    String? userEmail,
    String? userAvatarUrl,
  }) {
    return ExpenseSplit(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }

  /// User initials for avatar
  String get userInitials {
    if (userName == null || userName!.isEmpty) return '?';
    final parts = userName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName![0].toUpperCase();
  }

  @override
  String toString() {
    return 'ExpenseSplit(id: $id, user: $userName, amount: €$amount, isPaid: $isPaid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExpenseSplit &&
        other.id == id &&
        other.expenseId == expenseId &&
        other.userId == userId &&
        other.amount == amount &&
        other.isPaid == isPaid;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        expenseId.hashCode ^
        userId.hashCode ^
        amount.hashCode ^
        isPaid.hashCode;
  }
}
