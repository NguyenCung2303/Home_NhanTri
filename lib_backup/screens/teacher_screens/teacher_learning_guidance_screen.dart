import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/class_room_model.dart';
import '../../data/models/lichess_profile_model.dart';
import '../../data/models/stockfish_analysis_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/class_room_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/learning_guidance_repository.dart';
import '../../data/services/lichess_service.dart';
import '../../data/services/stockfish_analysis_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class TeacherLearningGuidanceScreen extends StatefulWidget {
  const TeacherLearningGuidanceScreen({super.key});

  @override
  State<TeacherLearningGuidanceScreen> createState() => _TeacherLearningGuidanceScreenState();
}

class _TeacherLearningGuidanceScreenState extends State<TeacherLearningGuidanceScreen> {
  final _strengthsController = TextEditingController();
  final _improvementsController = TextEditingController();
  final _orientationController = TextEditingController();
  final _classRepository = ClassRoomRepository();
  final _studentRepository = StudentRepository();
  final _lichessService = LichessService();
  final _stockfishService = StockfishAnalysisService();
  final _guidanceRepository = LearningGuidanceRepository();

  List<ClassRoomModel> _classRooms = [];
  List<StudentModel> _students = [];
  String? _selectedClassId;
  String? _selectedStudentId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingLichess = false;
  bool _isAnalyzingStockfish = false;
  LichessProfileModel? _lichessProfile;
  StockfishAnalysisModel? _stockfishAnalysis;
  String? _lichessError;
  String? _stockfishError;
  List<Map<String, dynamic>> _recentNotes = [];

  StudentModel? get _selectedStudent {
    for (final s in _students) {
      if (s.id == _selectedStudentId) return s;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitialData);
  }

  @override
  void dispose() {
    _strengthsController.dispose();
    _improvementsController.dispose();
    _orientationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final teacherId = context.read<AuthProvider>().currentUser?.id;
    if (teacherId == null) return;

    final classes = await _classRepository.getClassRoomsForTeacher(teacherId);
    List<StudentModel> students = [];
    String? selectedClassId;
    String? selectedStudentId;

    if (classes.isNotEmpty) {
      selectedClassId = classes.first.id;
      students = await _studentRepository.getStudentsByClass(selectedClassId);
      if (students.isNotEmpty) selectedStudentId = students.first.id;
    }

    if (!mounted) return;
    setState(() {
      _classRooms = classes;
      _students = students;
      _selectedClassId = selectedClassId;
      _selectedStudentId = selectedStudentId;
      _isLoading = false;
    });

    await _loadRecentNotes();
  }

  Future<void> _loadStudentsForClass(String classId) async {
    setState(() {
      _isLoading = true;
      _lichessProfile = null;
      _stockfishAnalysis = null;
      _lichessError = null;
      _stockfishError = null;
    });
    final students = await _studentRepository.getStudentsByClass(classId);
    if (!mounted) return;
    setState(() {
      _students = students;
      _selectedClassId = classId;
      _selectedStudentId = students.isNotEmpty ? students.first.id : null;
      _isLoading = false;
    });
  }

  Future<void> _loadRecentNotes() async {
    final teacherId = context.read<AuthProvider>().currentUser?.id;
    if (teacherId == null) return;
    final rows = await _guidanceRepository.getRecentByTeacher(teacherId);

    if (!mounted) return;
    setState(() => _recentNotes = rows);
  }

  Future<void> _fetchLichessData() async {
    final username = _selectedStudent?.lichessUsername;
    if (username == null || username.trim().isEmpty) {
      setState(() {
        _lichessProfile = null;
        _lichessError = 'Học sinh này chưa có username Lichess. Admin cần cập nhật trong hồ sơ học sinh.';
      });
      return;
    }

    setState(() {
      _isFetchingLichess = true;
      _lichessError = null;
      _lichessProfile = null;
    });

    try {
      final profile = await _lichessService.fetchProfile(username);
      if (!mounted) return;
      setState(() => _lichessProfile = profile);
      _prefillFromLichess(profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _lichessError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isFetchingLichess = false);
    }
  }

  Future<void> _analyzeWithStockfish() async {
    final username = _selectedStudent?.lichessUsername;
    if (username == null || username.trim().isEmpty) {
      setState(() {
        _stockfishAnalysis = null;
        _stockfishError = 'Học sinh này chưa có username Lichess để phân tích Stockfish.';
      });
      return;
    }

    setState(() {
      _isAnalyzingStockfish = true;
      _stockfishError = null;
      _stockfishAnalysis = null;
    });

    try {
      final analysis = await _stockfishService.analyzeUser(username, maxGames: 5, depth: 8);
      if (!mounted) return;
      setState(() => _stockfishAnalysis = analysis);
      _prefillFromStockfish(analysis);
    } catch (e) {
      if (!mounted) return;
      setState(() => _stockfishError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isAnalyzingStockfish = false);
    }
  }

  void _prefillFromStockfish(StockfishAnalysisModel analysis) {
    final issueText = analysis.topIssues.take(3).map((issue) {
      return '- Ở nước ${issue.moveNumber} (${issue.playedMove}), học sinh mắc ${_issueTypeVi(issue.type)} trong giai đoạn ${_phaseVi(issue.phase)}, làm mất khoảng ${issue.drop.toStringAsFixed(1)} điểm lợi thế.';
    }).join('\n');

    final winRate = analysis.statDouble('winRate').toStringAsFixed(1);
    _strengthsController.text = 'Stockfish đã phân tích ${analysis.gamesAnalyzed} ván gần nhất từ Lichess. '
        'Nhóm ván này có tỉ lệ thắng khoảng $winRate%, cho thấy học sinh đang có phong độ thi đấu tốt. '
        'Giáo viên vẫn nên đối chiếu thêm với biểu hiện trên lớp trước khi gửi nhận xét cho phụ huynh.';

    _improvementsController.text = analysis.topIssues.isEmpty
        ? (analysis.engineAvailable
            ? 'Stockfish chưa phát hiện lỗi nghiêm trọng lặp lại trong nhóm ván gần nhất. Học sinh cần tiếp tục duy trì thói quen phân tích sau ván đấu.'
            : 'Hệ thống hiện mới có thống kê cơ bản do Stockfish engine chưa được bật. Cần kiểm tra cấu hình backend để phân tích sâu từng nước đi.')
        : 'Một số điểm cần cải thiện:\n$issueText';

    _orientationController.text = analysis.suggestion;
  }

  String _issueTypeVi(String type) {
    switch (type) {
      case 'blunder':
        return 'sai lầm nghiêm trọng';
      case 'mistake':
        return 'sai lầm';
      case 'inaccuracy':
        return 'nước chưa chính xác';
      default:
        return type;
    }
  }

  String _phaseVi(String phase) {
    switch (phase) {
      case 'opening':
        return 'khai cuộc';
      case 'middlegame':
        return 'trung cuộc';
      case 'endgame':
        return 'tàn cuộc';
      default:
        return phase;
    }
  }

  void _prefillFromLichess(LichessProfileModel profile) {
    final ratingText = profile.ratings.entries.where((e) => e.value != null).map((e) => '${e.key}: ${e.value}').join(', ');
    final bestMode = profile.bestRatingMode;
    final bestRating = profile.bestRating;
    final winRate = profile.winRate.toStringAsFixed(1);

    _strengthsController.text = ratingText.isEmpty
        ? 'Học sinh đã có hồ sơ Lichess ${profile.username}. Cần giáo viên đánh giá thêm qua bài tập trên lớp vì dữ liệu rating public còn hạn chế.'
        : 'Học sinh có dữ liệu thi đấu rõ trên Lichess: $ratingText. Tổng ${profile.totalGames} ván, thắng ${profile.win}, hòa ${profile.draw}, thua ${profile.loss}, tỉ lệ thắng khoảng $winRate%.';

    _improvementsController.text = bestRating == null
        ? 'Cần tăng số lượng ván luyện tập và bài puzzle để có thêm dữ liệu đánh giá ổn định.'
        : 'Cần phân tích thêm các ván thua, đặc biệt là lỗi chiến thuật ở trung cuộc và khả năng chuyển ưu thế sang thắng lợi. Không nên chỉ nhìn rating vì dữ liệu Lichess cần đối chiếu với quan sát trên lớp.';

    _orientationController.text = bestRating == null
        ? 'Trong giai đoạn tới, giáo viên cho học sinh luyện puzzle cơ bản, ghi lại các lỗi thường gặp và khuyến khích chơi thêm các ván có kiểm soát thời gian để có dữ liệu đánh giá.'
        : 'Dựa trên hồ sơ Lichess của ${profile.username}, mức nổi bật hiện tại là ${bestMode ?? 'một chế độ'} $bestRating. Giáo viên định hướng học sinh tiếp tục duy trì điểm mạnh, luyện phân tích sau ván đấu, tăng bài puzzle theo chủ đề và tập trung sửa lỗi trung cuộc/tàn cuộc trong các buổi học tiếp theo.';
  }

  Future<void> _saveGuidance({bool sendToParent = false}) async {
    final teacherId = context.read<AuthProvider>().currentUser?.id;
    if (teacherId == null || _selectedClassId == null || _selectedStudentId == null) return;
    if (_orientationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn cần nhập định hướng học tập')));
      return;
    }

    setState(() => _isSaving = true);

    await _guidanceRepository.createGuidance(
      teacherId: teacherId,
      classId: _selectedClassId!,
      studentId: _selectedStudentId!,
      strengths: _strengthsController.text.trim(),
      improvements: _improvementsController.text.trim(),
      orientation: _orientationController.text.trim(),
      status: sendToParent ? 'SENT' : 'DRAFT',
    );

    _strengthsController.clear();
    _improvementsController.clear();
    _orientationController.clear();
    await _loadRecentNotes();

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sendToParent ? 'Đã gửi định hướng cho phụ huynh' : 'Đã lưu bản nháp định hướng học tập')),
    );
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
          : _classRooms.isEmpty
              ? const Center(
                  child: Text(
                    'Bạn chưa được phân công lớp nào để định hướng học tập.',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chọn lớp phụ trách', style: _labelStyle),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedClassId,
                            dropdownColor: AppColors.card,
                            decoration: _inputDecoration(),
                            items: _classRooms.map((c) => DropdownMenuItem(value: c.id, child: Text(c.className))).toList(),
                            onChanged: (value) {
                              if (value != null) _loadStudentsForClass(value);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Chọn học sinh', style: _labelStyle),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedStudentId,
                            dropdownColor: AppColors.card,
                            decoration: _inputDecoration(),
                            items: _students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))).toList(),
                            onChanged: (value) => setState(() {
                              _selectedStudentId = value;
                              _lichessProfile = null;
                              _stockfishAnalysis = null;
                              _lichessError = null;
                              _stockfishError = null;
                            }),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Lichess: ${_selectedStudent?.lichessUsername?.isNotEmpty == true ? _selectedStudent!.lichessUsername : 'chưa có'}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dữ liệu Lichess', style: _sectionTitleStyle),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isFetchingLichess ? null : _fetchLichessData,
                              icon: _isFetchingLichess
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.cloud_download),
                              label: const Text('Kéo dữ liệu từ Lichess'),
                            ),
                          ),
                          if (_lichessError != null) ...[
                            const SizedBox(height: 8),
                            Text(_lichessError!, style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600)),
                          ],
                          if (_lichessProfile != null) ...[
                            const SizedBox(height: 12),
                            _LichessSummary(profile: _lichessProfile!),
                          ],
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isAnalyzingStockfish ? null : _analyzeWithStockfish,
                              icon: _isAnalyzingStockfish
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.psychology),
                              label: const Text('Phân tích ván đấu bằng Stockfish'),
                            ),
                          ),
                          if (_stockfishError != null) ...[
                            const SizedBox(height: 8),
                            Text(_stockfishError!, style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600)),
                          ],
                          if (_stockfishAnalysis != null) ...[
                            const SizedBox(height: 12),
                            _StockfishSummary(analysis: _stockfishAnalysis!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Điểm mạnh', style: _labelStyle),
                          const SizedBox(height: 8),
                          TextField(controller: _strengthsController, maxLines: 2, decoration: _inputDecoration(hint: 'Ví dụ: tiếp thu nhanh, tư duy chiến thuật tốt')),
                          const SizedBox(height: 16),
                          const Text('Điểm cần cải thiện', style: _labelStyle),
                          const SizedBox(height: 8),
                          TextField(controller: _improvementsController, maxLines: 2, decoration: _inputDecoration(hint: 'Ví dụ: còn vội ở tàn cuộc, thiếu tập trung')),
                          const SizedBox(height: 16),
                          const Text('Định hướng học tập', style: _labelStyle),
                          const SizedBox(height: 8),
                          TextField(controller: _orientationController, maxLines: 4, decoration: _inputDecoration(hint: 'Nhập mục tiêu và hướng luyện tập tiếp theo')),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: _isSaving ? null : () => _saveGuidance(),
                                    child: const Text('Lưu nháp'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                    onPressed: _isSaving ? null : () => _saveGuidance(sendToParent: true),
                                    child: _isSaving
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Gửi phụ huynh', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gần đây', style: _sectionTitleStyle),
                          const SizedBox(height: 10),
                          if (_recentNotes.isEmpty)
                            const Text('Chưa có nhận xét nào được lưu.', style: TextStyle(color: AppColors.textSecondary))
                          else
                            ..._recentNotes.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text('${item['student_name']} • ${item['class_name']}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                                          Chip(label: Text(item['status'] == 'SENT' ? 'Đã gửi' : 'Nháp')),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(item['orientation']?.toString() ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _LichessSummary extends StatelessWidget {
  final LichessProfileModel profile;

  const _LichessSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final ratingRows = profile.ratings.entries.where((e) => e.value != null).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.username, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Tổng số ván: ${profile.totalGames} • Thắng: ${profile.win} • Hòa: ${profile.draw} • Thua: ${profile.loss}', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Tỉ lệ thắng: ${profile.winRate.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          if (ratingRows.isEmpty)
            const Text('Chưa có rating public đáng kể.', style: TextStyle(color: AppColors.textSecondary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ratingRows.map((e) => Chip(label: Text('${e.key}: ${e.value}'))).toList(),
            ),
        ],
      ),
    );
  }
}


class _StockfishSummary extends StatelessWidget {
  final StockfishAnalysisModel analysis;

  const _StockfishSummary({required this.analysis});

  String _issueTypeVi(String type) {
    switch (type) {
      case 'blunder':
        return 'lỗi nghiêm trọng';
      case 'mistake':
        return 'lỗi sai đáng chú ý';
      case 'inaccuracy':
        return 'nước đi chưa chính xác';
      default:
        return 'lỗi cần xem lại';
    }
  }

  String _issueChipLabel(String type) {
    switch (type) {
      case 'blunder':
        return 'Lỗi nghiêm trọng';
      case 'mistake':
        return 'Lỗi sai';
      case 'inaccuracy':
        return 'Chưa chính xác';
      default:
        return type;
    }
  }

  String _phaseVi(String phase) {
    switch (phase) {
      case 'opening':
        return 'khai cuộc';
      case 'middlegame':
        return 'trung cuộc';
      case 'endgame':
        return 'tàn cuộc';
      default:
        return 'ván đấu';
    }
  }

  String _phaseChipLabel(String phase) {
    switch (phase) {
      case 'opening':
        return 'Khai cuộc';
      case 'middlegame':
        return 'Trung cuộc';
      case 'endgame':
        return 'Tàn cuộc';
      default:
        return phase;
    }
  }

  String _mainPhase(Map<String, int> phaseCount) {
    if (phaseCount.isEmpty) return 'chưa xác định rõ giai đoạn';
    final sorted = phaseCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _phaseVi(sorted.first.key);
  }

  String _summaryText(Map<String, int> phaseCount) {
    final totalIssues = analysis.topIssues.length;
    final winRate = analysis.statDouble('winRate').toStringAsFixed(1);

    if (!analysis.engineAvailable) {
      return 'Hệ thống đã lấy được dữ liệu thi đấu, nhưng Stockfish engine chưa sẵn sàng nên hiện chỉ hiển thị thống kê cơ bản. Cần bật engine để nhận diện lỗi theo từng nước đi.';
    }

    if (totalIssues == 0) {
      return 'Stockfish đã phân tích ${analysis.gamesAnalyzed} ván gần nhất. Nhóm ván này có tỉ lệ thắng $winRate% và chưa ghi nhận lỗi lớn lặp lại. Học sinh nên tiếp tục duy trì thói quen phân tích sau mỗi ván.';
    }

    return 'Stockfish đã phân tích ${analysis.gamesAnalyzed} ván gần nhất. Nhóm ván này có tỉ lệ thắng $winRate%, nhưng vẫn ghi nhận $totalIssues điểm cần xem lại, tập trung nhiều ở giai đoạn ${_mainPhase(phaseCount)}.';
  }

  String _issueSentence(StockfishIssueModel issue) {
    return 'Ở nước ${issue.moveNumber} (${issue.playedMove}), học sinh mắc ${_issueTypeVi(issue.type)} trong giai đoạn ${_phaseVi(issue.phase)}, làm mất khoảng ${issue.drop.toStringAsFixed(1)} điểm lợi thế.';
  }

  String _issueAdvice(StockfishIssueModel issue) {
    switch (issue.phase) {
      case 'opening':
        return 'Gợi ý luyện tập: ôn lại nguyên tắc khai cuộc, phát triển quân nhanh và tránh đẩy tốt làm yếu vua quá sớm.';
      case 'middlegame':
        return 'Gợi ý luyện tập: tăng bài tập chiến thuật, luyện tính biến 2-3 nước và kiểm tra nước bắt quân, chiếu, đe dọa trước khi đi.';
      case 'endgame':
        return 'Gợi ý luyện tập: luyện tàn cuộc cơ bản, đặc biệt là vua và tốt, xe, hậu, cách chuyển ưu thế thành chiến thắng.';
      default:
        return 'Gợi ý luyện tập: sau mỗi ván nên xem lại các nước làm thay đổi đánh giá để hình thành thói quen tự phân tích.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final issueTypeCount = <String, int>{};
    final phaseCount = <String, int>{};
    for (final issue in analysis.topIssues) {
      issueTypeCount.update(issue.type, (v) => v + 1, ifAbsent: () => 1);
      phaseCount.update(issue.phase, (v) => v + 1, ifAbsent: () => 1);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  analysis.engineAvailable
                      ? 'Stockfish đã phân tích ${analysis.gamesAnalyzed} ván'
                      : 'Chưa bật Stockfish engine',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                ),
              ),
              Chip(label: Text(analysis.engineAvailable ? 'Engine OK' : 'Chỉ thống kê')),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _summaryText(phaseCount),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(label: 'Thắng', value: analysis.statInt('wins').toString(), color: AppColors.success),
              _StatPill(label: 'Thua', value: analysis.statInt('losses').toString(), color: AppColors.danger),
              _StatPill(label: 'Hòa', value: analysis.statInt('draws').toString(), color: AppColors.textSecondary),
              _StatPill(label: 'Tỉ lệ thắng', value: '${analysis.statDouble('winRate').toStringAsFixed(1)}%', color: AppColors.accent),
            ],
          ),
          if (analysis.engineError != null && analysis.engineError!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withOpacity(0.18)),
              ),
              child: Text(
                analysis.engineError!,
                style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (analysis.topIssues.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Nhận xét lỗi cần cải thiện', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...issueTypeCount.entries.map((e) => _IssueChip(label: _issueChipLabel(e.key), count: e.value)),
                ...phaseCount.entries.map((e) => _IssueChip(label: _phaseChipLabel(e.key), count: e.value)),
              ],
            ),
            const SizedBox(height: 12),
            ...analysis.topIssues.take(5).map(
              (issue) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _issueSentence(issue),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _issueAdvice(issue),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _IssueChip extends StatelessWidget {
  final String label;
  final int count;

  const _IssueChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text('$label: $count', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

InputDecoration _inputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.card,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent, width: 1.4)),
  );
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: child,
    );
  }
}

const _labelStyle = TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600);
const _sectionTitleStyle = TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16);
