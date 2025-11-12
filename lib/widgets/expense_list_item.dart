import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reusable expense list item widget with full functionality:
/// - Swipe to delete (right)
/// - Swipe to duplicate (left)
/// - Tap to show details modal
/// - Supports both dismissible and non-dismissible modes
class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final bool dismissible;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const ExpenseListItem({
    super.key,
    required this.expense,
    this.dismissible = true,
    this.onDeleted,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final listTile = Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.type),
          child: Icon(
            _getCategoryIcon(expense.type),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                expense.description,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (expense.isGroup)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '👥',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Gruppo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.moneyFlow.getLabel()),
            Text(
              DateFormat('dd/MM/yyyy').format(expense.date),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (expense.isGroup) ..._buildGroupInfo(context),
          ],
        ),
        trailing: Text(
          expense.formatAmount(expense.amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getAmountColor(expense.moneyFlow),
          ),
        ),
        onTap: () => _showExpenseDetails(context),
      ),
    );

    if (!dismissible) {
      return listTile;
    }

    return Dismissible(
      key: Key(expense.id.toString()),
      direction: DismissDirection.horizontal,
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 32),
            Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      background: Container(
        color: Colors.lightBlueAccent,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.copy, color: Colors.white, size: 32),
            Text(
              "Duplicate",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        switch (direction) {
          case DismissDirection.endToStart:
            return await _confirmDelete(context);
          case DismissDirection.startToEnd:
            await _duplicateExpense(context);
            return false; // Don't dismiss
          default:
            return false;
        }
      },
      onDismissed: (direction) async {
        await _onDismissed(context);
      },
      child: listTile,
    );
  }

  // Build group expense info widgets
  List<Widget> _buildGroupInfo(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final List<Widget> widgets = [];

    // Show who paid
    if (expense.paidBy != null) {
      final isPaidByCurrentUser = expense.paidBy == currentUserId;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isPaidByCurrentUser ? '💰 Hai pagato tu' : '💰 Pagato da altro membro',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPaidByCurrentUser ? Colors.green[700] : Colors.blue[700],
            ),
          ),
        ),
      );

      // Show debt indicator (async)
      widgets.add(
        FutureBuilder<double>(
          future: ExpenseService().calculateUserBalance(expense),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Calcolo debito...',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final balance = snapshot.data!;

            // Don't show if balance is 0
            if (balance.abs() < 0.01) {
              return const SizedBox.shrink();
            }

            if (balance > 0) {
              // User is owed money
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '↗️ +${balance.toStringAsFixed(2)}€ da recuperare',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              );
            } else {
              // User owes money
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '↙️ ${balance.toStringAsFixed(2)}€ devi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[700],
                  ),
                ),
              );
            }
          },
        ),
      );
    }

    return widgets;
  }

  // Show expense details in bottom sheet
  void _showExpenseDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.56,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dettagli Spesa',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildDetailRow('Descrizione', expense.description),
              _buildDetailRow('Importo', expense.formatAmount(expense.amount)),
              _buildDetailRow('Flusso', expense.moneyFlow.getLabel()),
              _buildDetailRow('Categoria', expense.type.label),
              _buildDetailRow(
                'Data',
                DateFormat('dd/MM/yyyy').format(expense.date),
              ),
              if (expense.isGroup) ...[
                const Divider(height: 30),
                Text(
                  'Info Gruppo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Tipo',
                  expense.splitType?.label ?? 'Non specificato',
                ),
                _buildDetailRow(
                  'Pagato da',
                  expense.paidBy == Supabase.instance.client.auth.currentUser?.id
                      ? 'Tu'
                      : 'Altro membro',
                ),
              ],
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _duplicateExpense(context);
                      },
                      icon: Icon(Icons.copy),
                      label: Text('Duplica'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editExpense(context);
                      },
                      icon: Icon(Icons.edit),
                      label: Text('Modifica'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteExpense(context);
                      },
                      icon: Icon(Icons.delete),
                      label: Text('Elimina'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  // Edit expense
  Future<void> _editExpense(BuildContext context) async {
    _openExpenseForm(
      context,
      expense: expense,
      title: "Modifica Spesa",
      isEdit: true,
    );
  }

  // Duplicate expense
  Future<void> _duplicateExpense(BuildContext context) async {
    _openExpenseForm(
      context,
      expense: expense,
      title: "Duplica Spesa",
      isEdit: false,
    );
  }

  // Delete expense with confirmation
  Future<void> _deleteExpense(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conferma eliminazione'),
        content: Text('Vuoi eliminare "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ExpenseService().deleteExpense(expense);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Spesa eliminata con successo'),
              backgroundColor: Colors.green,
            ),
          );
          onDeleted?.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore durante eliminazione: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Confirm delete (for dismissible)
  Future<bool?> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conferma eliminazione'),
        content: Text('Vuoi eliminare "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Handle dismissal
  Future<void> _onDismissed(BuildContext context) async {
    try {
      await ExpenseService().deleteExpense(expense);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Spesa eliminata'),
            backgroundColor: Colors.green,
          ),
        );
        onDeleted?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante eliminazione'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open expense form
  void _openExpenseForm(
    BuildContext context, {
    required Expense expense,
    required String title,
    required bool isEdit,
  }) {
    final ExpenseForm form = ExpenseForm.fromExpense(expense, isEdit: isEdit);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: form.getExpenseView(context),
            ),
          ),
        ),
      ),
    ).then((_) => onUpdated?.call());
  }

  // Helper methods for colors and icons
  Color _getCategoryColor(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return Colors.purple;
      case Tipologia.cibo:
        return Colors.green;
      case Tipologia.utenze:
        return Colors.blue;
      case Tipologia.prodottiCasa:
        return Colors.orange;
      case Tipologia.ristorante:
        return Colors.red;
      case Tipologia.tempoLibero:
        return Colors.pink;
      case Tipologia.altro:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return Icons.home;
      case Tipologia.cibo:
        return Icons.shopping_cart;
      case Tipologia.utenze:
        return Icons.bolt;
      case Tipologia.prodottiCasa:
        return Icons.cleaning_services;
      case Tipologia.ristorante:
        return Icons.restaurant;
      case Tipologia.tempoLibero:
        return Icons.sports_esports;
      case Tipologia.altro:
        return Icons.more_horiz;
    }
  }

  Color _getAmountColor(MoneyFlow flow) {
    switch (flow) {
      case MoneyFlow.carlToPit:
      case MoneyFlow.pitToCarl:
        return Colors.blue;
      case MoneyFlow.carlDiv2:
      case MoneyFlow.pitDiv2:
        return Colors.purple;
      case MoneyFlow.carlucci:
        return Colors.green;
      case MoneyFlow.pit:
        return Colors.orange;
    }
  }
}
