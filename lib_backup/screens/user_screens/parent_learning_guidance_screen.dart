import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/learning_guidance_repository.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class ParentLearningGuidanceScreen extends StatefulWidget {
  const ParentLearningGuidanceScreen({super.key});

  @override
  State<ParentLearningGuidanceScreen> createState() => _ParentLearningGuidanceScreenState();
}

class _ParentLearningGuidanceScreenState extends State<ParentLearningGuidanceScreen> {
  final _repository = LearningGuidanceRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    final parentUserId = context.read<AuthProvider>().currentUser?.id;
    if (parentUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final result = await _repository.getSentByParentUserId(parentUserId);
    if (!mounted) return;
    setState(() {
      _items = result;
      _isLoading = false;
    });
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Chưa rõ';
    final raw = value.toString();
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('Định hướng học tập'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Chưa có định hướng học tập nào được giáo viên gửi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['student_name']?.toString() ?? 'Học sinh',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Chip(label: Text(_formatDate(item['sent_at']))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item['class_name'] ?? 'Lớp'} • GV: ${item['teacher_name'] ?? 'Giáo viên'}',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 14),
                            if ((item['strengths']?.toString().trim().isNotEmpty ?? false)) ...[
                              const Text('Điểm mạnh', style: _titleStyle),
                              const SizedBox(height: 4),
                              Text(item['strengths'].toString(), style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 12),
                            ],
                            if ((item['improvements']?.toString().trim().isNotEmpty ?? false)) ...[
                              const Text('Điểm cần cải thiện', style: _titleStyle),
                              const SizedBox(height: 4),
                              Text(item['improvements'].toString(), style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 12),
                            ],
                            const Text('Định hướng tiếp theo', style: _titleStyle),
                            const SizedBox(height: 4),
                            Text(item['orientation']?.toString() ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

const _titleStyle = TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700);
