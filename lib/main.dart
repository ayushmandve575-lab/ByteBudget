import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const ByteBudgetApp());
}

class ByteBudgetApp extends StatelessWidget {
  const ByteBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ByteBudget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00B0FF),
          surface: Color(0xFF16161A),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class Transaction {
  final String id;
  final String title;
  final String category;
  final double amount;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'],
        title: map['title'],
        category: map['category'],
        amount: map['amount'],
      );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Transaction> _userExpenses = [];
  double _budgetLimit = 15000.0;
  
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedCategory = 'Food';

  final List<String> _categories = ['Food', 'Bills', 'Entertainment', 'Other'];

  // 🚀 CORE PARAMETER CONTROLLERS FOR VIVA EVALUATION MAPPINGS
  String _selectedTimeline = 'Month';     // Controls chart timeframe view toggle
  int _selectedThemeWallpaper = 0;        // 0 = Cyber Charcoal, 1 = Indigo, 2 = Emerald
  String _selectedLedgerFilter = 'All';   // Controls ledger timeline history viewport filters

  @override
  void initState() {
    super.initState();
    _loadLocalDatabase();
  }

  // 📂 NATIVE SANDBOX DIRECTORY PATH FINDER
  Future<File> _getLocalFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$filename');
  }

  // 📥 LOCAL STORAGE STRUCTURAL DESERIALIZATION
  Future<void> _loadLocalDatabase() async {
    try {
      final fileTx = await _getLocalFile('expenses.json');
      final fileBudget = await _getLocalFile('budget.txt');
      if (await fileBudget.exists()) {
        final budgetStr = await fileBudget.readAsString();
        setState(() => _budgetLimit = double.tryParse(budgetStr) ?? 15000.0);
      }
      if (await fileTx.exists()) {
        final txStr = await fileTx.readAsString();
        final List<dynamic> decoded = jsonDecode(txStr);
        setState(() {
          _userExpenses = decoded.map((item) => Transaction.fromMap(item)).toList();
        });
      }
    } catch (e) {
      debugPrint("Storage engine boot failure override: $e");
    }
  }

  // 📤 LOCAL STORAGE RECORD DATA SERIALIZATION
  Future<void> _syncLocalDatabase() async {
    try {
      final fileTx = await _getLocalFile('expenses.json');
      final fileBudget = await _getLocalFile('budget.txt');
      final String encoded = jsonEncode(_userExpenses.map((tx) => tx.toMap()).toList());
      await fileTx.writeAsString(encoded);
      await fileBudget.writeAsString(_budgetLimit.toString());
    } catch (e) {
      debugPrint("Storage engine database sync write breach: $e");
    }
  }

  // 🧮 MATHEMATICAL DATA AGGREGATION FILTERS
  double get _totalExpenses => _userExpenses.fold(0.0, (sum, item) => sum + item.amount);

  double get _dailyExpensesTotal {
    final todayStr = DateTime.now().toString().substring(0, 10);
    return _userExpenses
        .where((tx) => tx.id.substring(0, 10) == todayStr)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _weeklyExpensesTotal {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _userExpenses.where((tx) {
      final txDate = DateTime.tryParse(tx.id) ?? DateTime.now();
      return txDate.isAfter(sevenDaysAgo);
    }).fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _activeTimeframeTotal {
    if (_selectedTimeline == 'Day') return _dailyExpensesTotal;
    if (_selectedTimeline == 'Week') return _weeklyExpensesTotal;
    return _totalExpenses;
  }

  Map<String, double> get _categoryTotals {
    Map<String, double> chartMap = {'Food': 0.0, 'Bills': 0.0, 'Entertainment': 0.0, 'Other': 0.0};
    for (var tx in _userExpenses) {
      if (chartMap.containsKey(tx.category)) {
        chartMap[tx.category] = chartMap[tx.category]! + tx.amount;
      }
    }
    return chartMap;
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Food': return const Color(0xFF00E676);
      case 'Bills': return const Color(0xFF00B0FF);
      case 'Entertainment': return const Color(0xFFFFE082);
      default: return const Color(0xFFB0B0B0);
    }
  }

  // 📈 COMPILER ANALYTICAL VECTOR PIPELINE
  List<FlSpot> get _getChartSpots {
    if (_userExpenses.isEmpty) return [const FlSpot(0, 0)];
    List<FlSpot> spots = [];
    double runningSum = 0;
    
    final todayStr = DateTime.now().toString().substring(0, 10);
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final filteredTx = _userExpenses.reversed.where((tx) {
      if (_selectedTimeline == 'Day') return tx.id.substring(0, 10) == todayStr;
      if (_selectedTimeline == 'Week') {
        final txDate = DateTime.tryParse(tx.id) ?? DateTime.now();
        return txDate.isAfter(sevenDaysAgo);
      }
      return true;
    }).toList();

    if (filteredTx.isEmpty) return [const FlSpot(0, 0)];

    for (int i = 0; i < filteredTx.length; i++) {
      runningSum += filteredTx[i].amount;
      spots.add(FlSpot(i.toDouble(), runningSum));
    }
    return spots;
  }

  // 📑 INTEROPERABILITY ENGINE: SPREADSHEET PORTABILITY AND EXTRACTION (.CSV)
 // 📑 SPREADSHEET EXPORT DIALOG SELECT ENGINE
  Future<void> _exportToCSVSpreadsheet() async {
    try {
      StringBuffer buffer = StringBuffer();
      buffer.writeln('Transaction_ID,Merchant_Name,Category,Amount_INR');
      
      for (var tx in _userExpenses) {
        buffer.writeln('"${tx.id}","${tx.title}","${tx.category}",${tx.amount}');
      }
      
      final bytes = utf8.encode(buffer.toString());

      // 🌟 Correct, modern syntax for the updated file_picker package
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Select destination to save ByteBudget sheet:',
        fileName: 'ByteBudget_Ledger.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );

      if (outputPath != null) {
        final File fileRef = File(outputPath);
        await fileRef.writeAsBytes(bytes);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00B0FF),
            content: Text('📑 EXPORT SUCCESSFUL: saved to ${fileRef.path.split('/').last}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }
    } catch (e) {
      debugPrint("CSV serialization execution crash: $e");
    }
  }
  void _addNewTransaction(String title, double amount, String category) {
    if (title.isEmpty || amount <= 0) return;
    setState(() {
      _userExpenses.insert(
        0,
        Transaction(
          id: DateTime.now().toString(),
          title: title,
          category: category,
          amount: amount,
        ),
      );
    });
    _syncLocalDatabase();
    _titleController.clear();
    _amountController.clear();

    if (_totalExpenses > _budgetLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('🚨 TOTAL BUDGET LIMIT THRESHOLD BREACHED!', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  void _deleteTransaction(String id) {
    setState(() {
      _userExpenses.removeWhere((tx) => tx.id == id);
    });
    _syncLocalDatabase();
  }

  void _updateBudget(double targetLimit) {
    if (targetLimit <= 0) return;
    setState(() => _budgetLimit = targetLimit);
    _syncLocalDatabase();
    _budgetController.clear();
  }

  void _startUpdateBudgetFlow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(top: 24, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Adjust Threshold Target', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(controller: _budgetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New Threshold Target (₹)', border: OutlineInputBorder())),
                const SizedBox(height: 18),
                const Text('Dynamic Wallpaper Decoration System', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white60)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    WidgetKeyButton(title: 'Charcoal', color: const Color(0xFF0F0F11), onTap: () { setState(() => _selectedThemeWallpaper = 0); setModalState(() {}); }),
                    WidgetKeyButton(title: 'Midnight', color: const Color(0xFF0A0E17), onTap: () { setState(() => _selectedThemeWallpaper = 1); setModalState(() {}); }),
WidgetKeyButton(title: 'Emerald', color: const Color(0xFF07140E), onTap: () { setState(() => _selectedThemeWallpaper = 2); setModalState(() {}); }),
],
),
const SizedBox(height: 20),
ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF), padding: const EdgeInsets.symmetric(vertical: 16)),
onPressed: () {
_updateBudget(double.tryParse(_budgetController.text) ?? 0);
Navigator.of(context).pop();
},
child: const Text('Save Parameters', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
),
],
),
);
}
),
);
}
void startAddNewTransactionFlow(BuildContext ctx) {
showModalBottomSheet(
context: ctx,
isScrollControlled: true,
backgroundColor: const Color(0xFF16161A),
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
builder: (_) {
return StatefulBuilder(
builder: (BuildContext context, StateSetter setModalState) {
return Padding(
padding: EdgeInsets.only(top: 24, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const Text('Log New Expense Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 14),
TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Merchant Name', border: OutlineInputBorder())),
const SizedBox(height: 12),
TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
const SizedBox(height: 12),
//ignore: deprecated_member_use
DropdownButtonFormField(
initialValue: _selectedCategory,
dropdownColor: const Color(0xFF16161A),
decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Category'),
items: _categories.map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
onChanged: (newVal) => setModalState(() => _selectedCategory = newVal!),
),
const SizedBox(height: 16),
ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
onPressed: () {
_addNewTransaction(_titleController.text, double.tryParse(_amountController.text) ?? 0, _selectedCategory);
Navigator.of(ctx).pop();
},
child: const Text('Confirm Entry', style: TextStyle(fontWeight: FontWeight.bold)),
),
],
),
);
},
);
},
);
}
Map<String, double> _getCategoryTotalsForTimeframe() {
    Map<String, double> filteredTotals = {};
    final now = DateTime.now();
    
    for (var tx in _userExpenses) {
      final txDate = DateTime.tryParse(tx.id) ?? now;
      bool matchesTimeframe = true;
      
      if (_selectedTimeline == 'Day') {
        matchesTimeframe = txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
      } else if (_selectedTimeline == 'Week') {
        matchesTimeframe = now.difference(txDate).inDays <= 7;
      } else if (_selectedTimeline == 'Month') {
        matchesTimeframe = txDate.year == now.year && txDate.month == now.month;
      }
      
      if (matchesTimeframe) {
        filteredTotals[tx.category] = (filteredTotals[tx.category] ?? 0) + tx.amount;
      }
    }
    return filteredTotals.isEmpty ? _categoryTotals : filteredTotals;
  }
@override
  Widget build(BuildContext context) {
    final bool isOverBudget = _totalExpenses > _budgetLimit;

    BoxDecoration currentWallpaper;
    switch (_selectedThemeWallpaper) {
      case 1: currentWallpaper = const BoxDecoration(color: Color(0xFF0A0E17)); break; 
      case 2: currentWallpaper = const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF07140E), Color(0xFF0F0F11)], begin: Alignment.topLeft, end: Alignment.bottomRight)); break; 
      default: currentWallpaper = const BoxDecoration(color: Color(0xFF0F0F11)); 
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ByteBudget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.tune, color: Color(0xFF00B0FF)), onPressed: () => _startUpdateBudgetFlow(context))
        ],
      ),
      body: Container(
        decoration: currentWallpaper,
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isOverBudget ? [const Color(0xFF3A1C1C), const Color(0xFF16161A)] : [const Color(0xFF1D1E2C), const Color(0xFF16161A)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: isOverBudget ? Colors.redAccent : Colors.white10),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DYNAMIC SPEND ANALYSIS VECTOR: $_selectedTimeline', style: TextStyle(color: isOverBudget ? Colors.redAccent : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('₹${_activeTimeframeTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Builder(
                    builder: (context) {
                      final bool isExceeded = _totalExpenses > _budgetLimit;
                      final double remainingAmount = _budgetLimit - _totalExpenses;
                      final double overSpentAmount = _totalExpenses - _budgetLimit;
                      
                      return Text(
                        'Monthly Ceiling Threshold: ₹${_budgetLimit.toStringAsFixed(0)} | Full Month Aggregation: ₹${_totalExpenses.toStringAsFixed(0)} ' 
                        '${isExceeded 
                          ? '| ⚠️ Over-Spent: ₹${overSpentAmount.toStringAsFixed(0)}' 
                          : '| Remaining: ₹${remainingAmount.toStringAsFixed(0)}'}',
                        style: TextStyle(
                          color: isExceeded ? Colors.redAccent : Colors.white38, 
                          fontSize: 11,
                          fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(value: (_totalExpenses / _budgetLimit).clamp(0.0, 1.0), backgroundColor: Colors.white10, color: isOverBudget ? Colors.redAccent : const Color(0xFF00E676), minHeight: 8),
                  ),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final ratio = _totalExpenses / _budgetLimit;
                      if (ratio >= 1.0) {
                        return const Text('⚠️ CRITICAL STATUS: BUDGET EXCEEDED / ANOMALY DETECTED', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold));
                      } else if (ratio >= 0.90) {
                        return const Text('🚨 ALERT: 90% THRESHOLD BREACHED / SYSTEM CEILING NEAR', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold));
                      } else if (ratio >= 0.50) {
                        return const Text('⚡ WARNING: 50% RESOURCE CONSUMPTION VECTOR HIT', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold));
                      }
                      return const Text('🛡️ SYSTEM STATE: NOMINAL CONFIGURATION', style: TextStyle(color: Colors.lightGreenAccent, fontSize: 10, fontWeight: FontWeight.bold));
                    },
                  ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chronological Trajectory Map', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: ['Day', 'Week', 'Month'].map((timeframe) {
                        final bool isSelected = _selectedTimeline == timeframe;
                        return ChoiceChip(
                          label: Text(timeframe, style: TextStyle(fontSize: 10, color: isSelected ? Colors.black : Colors.white)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF00E676),
                          backgroundColor: const Color(0xFF16161A),
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                _selectedTimeline = timeframe;
                                // Forces the graphics engine to recalculate active matrix plots
                                _getCategoryTotalsForTimeframe(); 
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _userExpenses.isEmpty
                    ? const SizedBox(height: 140, child: Center(child: Text('Add transactions to visualize analytics mappings.', style: TextStyle(color: Colors.white24, fontSize: 12))))
                    : SizedBox(
                        height: 140,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4, centerSpaceRadius: 35,
                            sections: _getCategoryTotalsForTimeframe().entries.map((entry) {
                              return PieChartSectionData(
                                color: _getCategoryColor(entry.key), value: entry.value == 0 ? 0.1 : entry.value,
                                title: entry.value > 0 ? '${entry.key}\n₹${entry.value.toStringAsFixed(0)}' : '', radius: 40,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                const SizedBox(height: 25),
                const Text('Expense Trajectory Vector Curve', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 130,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false), titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getChartSpots, isCurved: true, color: const Color(0xFF00B0FF), barWidth: 4, isStrokeCapRound: true, dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: const Color(0xFF00B0FF).withAlpha(20)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16161A), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white10))),
                  onPressed: () => startAddNewTransactionFlow(context),
                  icon: const Icon(Icons.add_card, color: Color(0xFF00E676)),
                  label: const Text('Log New Expense Entry', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transaction Ledger View', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _selectedLedgerFilter,
                          dropdownColor: const Color(0xFF16161A),
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          underline: const SizedBox(),
                          items: ['All', 'Today', 'History'].map((String filterVal) {
                            return DropdownMenuItem<String>(value: filterVal, child: Text(filterVal));
                          }).toList(),
                          onChanged: (newVal) => setState(() => _selectedLedgerFilter = newVal!),
                        ),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.receipt_long, color: Color(0xFF00B0FF), size: 20), onPressed: _exportToCSVSpreadsheet),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final filteredLedgerList = _userExpenses.where((tx) {
                      final todayStr = DateTime.now().toString().substring(0, 10);
                      if (_selectedLedgerFilter == 'Today') return tx.id.substring(0, 10) == todayStr;
                      if (_selectedLedgerFilter == 'History') return tx.id.substring(0, 10) != todayStr;
                      return true;
                    }).toList();

                    return filteredLedgerList.isEmpty
                        ? const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Text('No matching transactions found.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24)))
                        : ListView.builder(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filteredLedgerList.length,
                            itemBuilder: (ctx, index) {
                              final tx = filteredLedgerList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius:
                                 BorderRadius.circular(14), side: const 
                                 BorderSide(color: Colors.white10)),
                                 child: ListTile(
                                  contentPadding: const 
                                  EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  title: Text(tx.title, style: const TextStyle(fontWeight: 
                                  FontWeight.bold, fontSize: 15)),
                                  subtitle: Text(tx.category, style: TextStyle(color: 
                                  _getCategoryColor(tx.category), fontSize: 11, 
                                  fontWeight: FontWeight.w500)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('-₹${tx.amount.toStringAsFixed(2)}', style: const
                                       TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                        color: Colors.white)),
                                        const SizedBox(width: 8),
                                        IconButton(icon: const Icon(Icons.delete_outline,
                                         color: Colors.redAccent, size: 22), onPressed: () => 
                                         _deleteTransaction(tx.id)),
                                         ],
                                         ),
                                         ),
                                         );
                                         },
                                         );
                                         }
                                         ),
                                         const SizedBox(height: 30),
                                         ],
                                         ),
                                         ),
                                         ),
                                         ),
                                         );
                                         }
                                         }
class WidgetKeyButton extends StatelessWidget {
final String title;
final Color color;
final VoidCallback onTap;
const WidgetKeyButton({required this.title, required this.color, required this.onTap, super.key});
@override
Widget build(BuildContext context) {
return ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
onPressed: onTap,
child: Text(title, style: const TextStyle(fontSize: 11, color: Colors.white)),
);
}
}


