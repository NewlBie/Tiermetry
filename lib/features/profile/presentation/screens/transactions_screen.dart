import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A simple data model for a transaction
class Transaction {
  final String title;
  final String type; // e.g., "Payment", "Refund", "Subscription"
  final double amount;
  final DateTime date;
  final IconData icon;

  Transaction({
    required this.title,
    required this.type,
    required this.amount,
    required this.date,
    required this.icon,
  });
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  // Mock data for the transaction list
  static final List<Transaction> _transactions = [
    Transaction(title: "Monthly Subscription", type: "Subscription", amount: -9.99, date: DateTime(2025, 8, 25), icon: Icons.star_rounded),
    Transaction(title: "Ticket Purchase: Event Name", type: "Payment", amount: -45.50, date: DateTime(2025, 8, 20), icon: Icons.local_activity_rounded),
    Transaction(title: "Refund for cancelled event", type: "Refund", amount: 25.00, date: DateTime(2025, 8, 18), icon: Icons.refresh_rounded),
    Transaction(title: "Arena Booking Fee", type: "Payment", amount: -150.00, date: DateTime(2025, 8, 12), icon: Icons.sports_esports_rounded),
    Transaction(title: "Marketplace Sale", type: "Deposit", amount: 75.00, date: DateTime(2025, 8, 5), icon: Icons.storefront_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'My Transactions',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final transaction = _transactions[index];
                  return _buildTransactionItem(context, transaction);
                },
                childCount: _transactions.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    final isCredit = transaction.amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(transaction.icon, color: Colors.white70),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  transaction.type,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            "${isCredit ? '+' : ''}\$${transaction.amount.toStringAsFixed(2)}",
            style: GoogleFonts.plusJakartaSans(
              color: isCredit ? Colors.greenAccent : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
