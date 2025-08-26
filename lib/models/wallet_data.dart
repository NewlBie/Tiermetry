class WalletData {
  final String balance;
  final String earned;
  final String spent;
  final String txns;

  WalletData({
    required this.balance,
    required this.earned,
    required this.spent,
    required this.txns,
  });

  // ⬇️ ADD THIS METHOD to fix the error
  WalletData copyWith({
    String? balance,
    String? earned,
    String? spent,
    String? txns,
  }) {
    return WalletData(
      balance: balance ?? this.balance,
      earned: earned ?? this.earned,
      spent: spent ?? this.spent,
      txns: txns ?? this.txns,
    );
  }
}