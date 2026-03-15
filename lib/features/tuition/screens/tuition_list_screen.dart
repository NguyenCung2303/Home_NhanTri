import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/tuition_model.dart';
import '../providers/tuition_provider.dart';
import 'add_tuition_screen.dart';

class TuitionListScreen extends StatefulWidget {
  const TuitionListScreen({super.key});

  @override
  State<TuitionListScreen> createState() => _TuitionListScreenState();
}

class _TuitionListScreenState extends State<TuitionListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TuitionProvider>().loadTuitions());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return Colors.green;
      case 'OVERDUE':
        return Colors.red;
      case 'UNPAID':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TuitionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách học phí'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.tuitions.length,
              itemBuilder: (context, index) {
                final tuition = provider.tuitions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text('${tuition.amount.toStringAsFixed(0)}đ'),
                    subtitle: Text(
                      'Hạn đóng: ${tuition.dueDate}\nTrạng thái: ${tuition.status}',
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check_circle, color: _statusColor(tuition.status)),
                          onPressed: tuition.status == 'PAID'
                              ? null
                              : () => provider.markAsPaid(tuition.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => provider.deleteTuition(tuition.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTuitionScreen(),
            ),
          );

          if (!mounted) return;
          context.read<TuitionProvider>().loadTuitions();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}