import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/parent_model.dart';
import '../providers/parent_provider.dart';

class ParentListScreen extends StatefulWidget {
  const ParentListScreen({super.key});

  @override
  State<ParentListScreen> createState() => _ParentListScreenState();
}

class _ParentListScreenState extends State<ParentListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ParentProvider>().loadParents());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách phụ huynh'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.parents.length,
              itemBuilder: (context, index) {
                final parent = provider.parents[index];
                return ListTile(
                  title: Text(parent.fullName),
                  subtitle: Text(parent.phone ?? 'Chưa có số điện thoại'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.deleteParent(parent.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final now = DateTime.now().millisecondsSinceEpoch.toString();

          final parent = ParentModel(
            id: now,
            userId: 'user_$now',
            fullName: 'Phụ huynh mới',
            phone: '09$now',
            email: 'parent$now@gmail.com',
            address: 'Hà Nội',
            relationshipToStudent: 'Mẹ',
            note: '',
            createdAt: DateTime.now().toIso8601String(),
          );

          await provider.addParent(parent);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}