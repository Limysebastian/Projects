import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Mycpp());
}

class Mycpp extends StatelessWidget {
  const Mycpp({super.key});

  @override
  Widget build(BuildContext context) {
    const lightBlue = Color(0xFF81D4FA);
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Income & Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: lightBlue,
        scaffoldBackgroundColor: black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.transparent,
          foregroundColor: white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: lightBlue.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: white.withOpacity(0.1),
            foregroundColor: white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: white.withOpacity(0.2)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: lightBlue.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: lightBlue, width: 2)),
          filled: true,
          fillColor: white.withOpacity(0.1),
          labelStyle: TextStyle(color: white.withOpacity(0.7)),
          prefixIconColor: white,
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: Colors.transparent,
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.transparent,
        ),
      ),
      home: const Myincom(),
    );
  }
}

class Transaction {
  String id;
  final String type;
  final double amount;
  final String details;
  final DateTime date;
  final String category;

  Transaction({
    this.id = '',
    required this.type,
    required this.amount,
    required this.details,
    required this.date,
    required this.category,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      type: data['type'] ?? 'Expense',
      amount: (data['amount'] as num).toDouble(),
      details: data['details'] ?? 'No details',
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? 'Other',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'amount': amount,
      'details': details,
      'date': Timestamp.fromDate(date),
      'category': category,
    };
  }
}

class Myincom extends StatefulWidget {
  const Myincom({super.key});

  @override
  State<Myincom> createState() => _MyincomState();
}

class _MyincomState extends State<Myincom> with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _otherCategoryController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fade;

  final lightBlue = const Color(0xFF81D4FA);
  final black = const Color(0xFF000000);
  final white = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    _otherCategoryController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showAddTransactionBottomSheet() {
    String selectedType = 'Expense';
    DateTime selectedDate = DateTime.now();
    String selectedCategory = 'Other';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [lightBlue, black.withOpacity(0.05)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: lightBlue.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInsideBottomSheet) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Transaction',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: white, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)]),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Type',
                      prefixIcon: Icon(Icons.category),
                    ),
                    style: TextStyle(color: white),
                    dropdownColor: black,
                    items: <String>['Income', 'Expense'].map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(color: white)))).toList(),
                    onChanged: (String? newValue) {
                      setStateInsideBottomSheet(() {
                        selectedType = newValue!;
                        if (selectedType == 'Income') {
                          selectedCategory = 'Salary';
                        } else {
                          selectedCategory = 'Other';
                        }
                        _otherCategoryController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.label),
                    ),
                    style: TextStyle(color: white),
                    dropdownColor: black,
                    items: (selectedType == 'Income' ? ['Salary', 'Freelance', 'Investment', 'Gift', 'Other'] : ['Food', 'Transport', 'Rent', 'Utilities', 'Entertainment', 'Shopping', 'Health', 'Education', 'Other'])
                        .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(color: white))))
                        .toList(),
                    onChanged: (String? newValue) {
                      setStateInsideBottomSheet(() {
                        selectedCategory = newValue!;
                        _otherCategoryController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedCategory == 'Other')
                    Column(
                      children: [
                        TextField(
                          controller: _otherCategoryController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Category Name',
                            hintText: 'e.g., Groceries, Car Maintenance',
                            prefixIcon: Icon(Icons.edit),
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                          style: TextStyle(color: white),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: 'Enter amount (e.g., 500.00)',
                      prefixIcon: Icon(Icons.attach_money),
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    style: TextStyle(color: white),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Details (Optional)',
                      hintText: 'e.g., Dinner with friends',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description),
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    style: TextStyle(color: white),
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                      style: TextStyle(fontSize: 16, color: white),
                    ),
                    trailing: Icon(Icons.calendar_today, color: white),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: lightBlue,
                              onPrimary: white,
                              surface: black,
                              onSurface: white,
                            ),
                            dialogBackgroundColor: black,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null && picked != selectedDate) {
                        setStateInsideBottomSheet(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final double? enteredAmount = double.tryParse(_amountController.text);
                      if (enteredAmount == null || enteredAmount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid positive amount.'), backgroundColor: Colors.redAccent),
                        );
                        return;
                      }
                      String finalCategory = selectedCategory;
                      if (selectedCategory == 'Other') {
                        finalCategory = _otherCategoryController.text.trim();
                        if (finalCategory.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a custom category or select an existing one.'), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }
                      }
                      final newTransaction = Transaction(
                        type: selectedType,
                        amount: enteredAmount,
                        details: _detailsController.text.trim().isEmpty ? (selectedType == 'Income' ? 'General Income' : 'General Expense') : _detailsController.text.trim(),
                        date: selectedDate,
                        category: finalCategory,
                      );
                      try {
                        await FirebaseFirestore.instance.collection('transactions').add(newTransaction.toFirestore());
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction saved successfully!'), backgroundColor: Colors.green),
                        );
                        _amountController.clear();
                        _detailsController.clear();
                        _otherCategoryController.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save transaction: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Transaction', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: Colors.transparent,
                      foregroundColor: white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: lightBlue.withOpacity(0.3)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [lightBlue.withOpacity(0.1), white.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lightBlue.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Confirm Deletion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: white)),
                const SizedBox(height: 12),
                Text('Are you sure you want to delete this transaction?', style: TextStyle(color: white)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('transactions').doc(transactionId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete transaction: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: black,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [lightBlue.withOpacity(0.8), black], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
          ),
          title: Text(
            'Income & Expense Tracker',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: white, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)]),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [black, black.withOpacity(0.8), Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('transactions').orderBy('date', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: lightBlue));
                  }
                  final List<Transaction> transactions = snapshot.data!.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
                  double totalIncome = 0.0, totalExpense = 0.0, totalBalance = 0.0;
                  for (var transaction in transactions) {
                    if (transaction.type == 'Income') {
                      totalIncome += transaction.amount;
                      totalBalance += transaction.amount;
                    } else {
                      totalExpense += transaction.amount;
                      totalBalance -= transaction.amount;
                    }
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [lightBlue.withOpacity(0.1), white.withOpacity(0.05)]),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: lightBlue.withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [lightBlue, black]),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                    child: Icon(Icons.account_balance_wallet, color: white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Income & Expense Tracker', style: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const Text('Manage your finances', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [black, lightBlue.withOpacity(0.4), black.withOpacity(0.8)]),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: white.withOpacity(0.1)),
                                boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                children: [
                                  Text('Current Balance:', style: TextStyle(fontSize: 18, color: white)),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${totalBalance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: totalBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                      shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [black, lightBlue.withOpacity(0.4), black.withOpacity(0.8)]),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: white.withOpacity(0.1)),
                                      boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                    ),
                                    child: Column(
                                      children: [
                                        Text('Total Income', style: TextStyle(fontSize: 14, color: white)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${totalIncome.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [black, lightBlue.withOpacity(0.4), black.withOpacity(0.8)]),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: white.withOpacity(0.1)),
                                      boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                    ),
                                    child: Column(
                                      children: [
                                        Text('Total Expense', style: TextStyle(fontSize: 14, color: white)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${totalExpense.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Recent Transactions:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: white, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: transactions.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No transactions added yet. Click the "+" button below to record your income or expenses!',
                                    style: TextStyle(fontSize: 16, color: white.withOpacity(0.7), shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 2)]),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = transactions[index];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [black, lightBlue.withOpacity(0.4), black.withOpacity(0.8)]),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: white.withOpacity(0.1)),
                                      boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: white.withOpacity(0.15),
                                        child: Icon(
                                          transaction.type == 'Income' ? Icons.arrow_downward : Icons.arrow_upward,
                                          color: transaction.type == 'Income' ? Colors.green.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                      title: Text(
                                        transaction.details,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: white),
                                      ),
                                      subtitle: Text(
                                        '${DateFormat('MMM dd, yyyy').format(transaction.date)} - ${transaction.category}',
                                        style: TextStyle(color: white.withOpacity(0.7), fontSize: 13),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₹${transaction.amount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: transaction.type == 'Income' ? Colors.green.shade700 : Colors.red.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.grey),
                                            onPressed: () => _deleteTransaction(transaction.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                              BoxShadow(color: black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (transactions.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Add some transactions to see the report!'), backgroundColor: Colors.orange),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => GraphPage(transactions: transactions),
                                  transitionsBuilder: (_, a, __, c) => SlideTransition(position: a.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)), child: c),
                                ),
                              );
                            },
                            icon: const Icon(Icons.pie_chart, size: 28),
                            label: const Text('View Report', style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 55),
                              backgroundColor: Colors.transparent,
                              foregroundColor: white,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_sync_outlined, color: lightBlue, size: 16),
                            const SizedBox(width: 8),
                            Text('Transactions synced & secured', style: TextStyle(color: white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTransactionBottomSheet,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [lightBlue, black], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Center(child: Icon(Icons.add, color: white, size: 24)),
          ),
        ),
      );
}

class GraphPage extends StatefulWidget {
  final List<Transaction> transactions;

  const GraphPage({Key? key, required this.transactions}) : super(key: key);

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with TickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _controller;
  late Animation<double> _fade;
  final lightBlue = const Color(0xFF81D4FA);
  final black = const Color(0xFF000000);
  final white = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _getCategoryColors() {
    return [
      Colors.green.shade700,
      Colors.lightGreen.shade700,
      Colors.lime.shade700,
      Colors.red.shade700,
      Colors.blue.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.teal.shade700,
      Colors.brown.shade700,
      Colors.indigo.shade700,
      Colors.cyan.shade700,
      Colors.pink.shade700,
      Colors.deepOrange.shade700,
      Colors.amber.shade700,
      Colors.grey.shade700,
    ];
  }

  List<PieChartSectionData> getAllCategorySections(Map<String, double> categoryAmounts, Map<String, String> categoryTypes) {
    if (categoryAmounts.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          color: white.withOpacity(0.3),
          title: 'No Data',
          radius: 60,
          titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: white),
        ),
      ];
    }
    final double totalAmount = categoryAmounts.values.fold(0, (sum, item) => sum + item);
    final sortedEntries = categoryAmounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final List<Color> colors = _getCategoryColors();
    Map<String, Color> assignedColors = {};
    int expenseColorIndex = 0, incomeColorIndex = 0;
    for (var entry in sortedEntries) {
      if (categoryTypes[entry.key] == 'Income') {
        assignedColors[entry.key] = colors[incomeColorIndex % 3];
        incomeColorIndex++;
      } else {
        assignedColors[entry.key] = colors[3 + (expenseColorIndex % (colors.length - 3))];
        expenseColorIndex++;
      }
    }
    return sortedEntries.asMap().entries.map((entryWithIndex) {
      final index = entryWithIndex.key;
      final entry = entryWithIndex.value;
      final isTouched = index == touchedIndex;
      final percentage = (entry.value / totalAmount * 100).toStringAsFixed(1);
      final categoryName = entry.key;
      final categoryType = categoryTypes[categoryName] ?? 'Expense';
      final color = assignedColors[categoryName] ?? Colors.grey;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: isTouched ? '$categoryName\n₹${entry.value.toStringAsFixed(2)}' : '$percentage%',
        radius: isTouched ? 100.0 : 90.0,
        titleStyle: TextStyle(
          fontSize: isTouched ? 18 : 14,
          fontWeight: FontWeight.bold,
          color: white,
          shadows: [Shadow(color: black.withOpacity(0.5), blurRadius: 2)],
        ),
        badgeWidget: isTouched ? _buildBadge(categoryName, categoryType, color) : null,
        titlePositionPercentageOffset: isTouched ? 0.6 : 0.55,
      );
    }).toList();
  }

  Widget _buildBadge(String categoryName, String type, Color color) => Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: white.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: black.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 2))],
          ),
          child: Text(
            '$categoryName ($type)',
            style: TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      );

  Widget _buildLegendItem(Color color, String title, {bool isIncome = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: white.withOpacity(0.2))),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: isIncome ? FontWeight.bold : FontWeight.normal, color: isIncome ? Colors.green.shade700 : white.withOpacity(0.8)),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return Scaffold(
        backgroundColor: black,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [lightBlue.withOpacity(0.8), black], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
          ),
          title: Text('Income & Expenses Report', style: TextStyle(color: white, fontSize: 22, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)])),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [black, black.withOpacity(0.8), Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No transaction data available to generate a report.\nPlease add some income or expenses first!',
                    style: TextStyle(fontSize: 16, color: Colors.white70, shadows: [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 2)]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final Map<String, double> categoryAmounts = {};
    final Map<String, String> categoryTypes = {};
    for (var transaction in widget.transactions) {
      categoryAmounts.update(transaction.category, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
      categoryTypes[transaction.category] = transaction.type;
    }
    final sortedCategoryAmounts = Map.fromEntries(categoryAmounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    final sections = getAllCategorySections(sortedCategoryAmounts, categoryTypes);
    final sortedCategoryNames = sortedCategoryAmounts.keys.toList();
    final Map<String, Color> legendColors = {};
    int expenseColorCounter = 0, incomeColorCounter = 0;
    final List<Color> colors = _getCategoryColors();
    for (var categoryName in sortedCategoryNames) {
      if (categoryTypes[categoryName] == 'Income') {
        legendColors[categoryName] = colors[incomeColorCounter % 3];
        incomeColorCounter++;
      } else {
        legendColors[categoryName] = colors[3 + (expenseColorCounter % (colors.length - 3))];
        expenseColorCounter++;
      }
    }
    return Scaffold(
      backgroundColor: black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [lightBlue.withOpacity(0.8), black], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
          ),
        ),
        title: Text('Detailed Financial Report', style: TextStyle(color: white, fontSize: 22, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)])),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [black, black.withOpacity(0.8), Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [lightBlue.withOpacity(0.1), white.withOpacity(0.05)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lightBlue.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [lightBlue, black]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Icon(Icons.pie_chart, color: white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Financial Report', style: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const Text('Analyze your transactions', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Overall Financial Breakdown by Category',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: white, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 4,
                          centerSpaceRadius: 60,
                          sections: sections,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Category Details:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: white, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      alignment: WrapAlignment.center,
                      children: sortedCategoryNames
                          .map((categoryName) => _buildLegendItem(legendColors[categoryName] ?? Colors.grey, '$categoryName (${categoryTypes[categoryName] ?? ''})', isIncome: categoryTypes[categoryName] == 'Income'))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}