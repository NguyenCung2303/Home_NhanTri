class TuitionModel {
  final String id;
  final String studentId;
  final String classId;
  final double amount;
  final String dueDate;
  final String? paidDate;
  final String status;
  final String? paymentMethod;
  final String? transactionCode;
  final String? qrContent;
  final String? note;
  final String? tuitionPeriod;
  final String createdAt;

  TuitionModel({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.paymentMethod,
    this.transactionCode,
    this.qrContent,
    this.note,
    this.tuitionPeriod,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'class_id': classId,
      'amount': amount,
      'due_date': dueDate,
      'paid_date': paidDate,
      'status': status,
      'payment_method': paymentMethod,
      'transaction_code': transactionCode,
      'qr_content': qrContent,
      'note': note,
      'tuition_period': tuitionPeriod,
      'created_at': createdAt,
    };
  }

  factory TuitionModel.fromMap(Map<String, dynamic> map) {
    return TuitionModel(
      id: map['id'],
      studentId: map['student_id'],
      classId: map['class_id'],
      amount: (map['amount'] as num).toDouble(),
      dueDate: map['due_date'],
      paidDate: map['paid_date'],
      status: map['status'],
      paymentMethod: map['payment_method'],
      transactionCode: map['transaction_code'],
      qrContent: map['qr_content'],
      note: map['note'],
      tuitionPeriod: map['tuition_period'],
      createdAt: map['created_at'],
    );
  }

  factory TuitionModel.fromFirestore(
    String id,
    Map<String, dynamic> fields,
  ) {
    String str(String key) {
      final value = fields[key];
      if (value == null) return '';

      return value['stringValue']?.toString() ??
          value['timestampValue']?.toString() ??
          value['integerValue']?.toString() ??
          value['doubleValue']?.toString() ??
          '';
    }

    double number(String key) {
      final value = fields[key];
      if (value == null) return 0;

      final raw = value['doubleValue'] ??
          value['integerValue'] ??
          value['stringValue'];

      if (raw == null) return 0;
      return double.tryParse(raw.toString()) ?? 0;
    }

    return TuitionModel(
      id: id,
      studentId: str('studentId'),
      classId: str('classId'),
      amount: number('amount'),
      dueDate: str('dueDate'),
      paidDate: str('paidDate').isNotEmpty ? str('paidDate') : null,
      status: str('status').isNotEmpty ? str('status') : 'UNPAID',
      paymentMethod:
          str('paymentMethod').isNotEmpty ? str('paymentMethod') : null,
      transactionCode:
          str('transactionCode').isNotEmpty ? str('transactionCode') : null,
      qrContent: str('qrContent').isNotEmpty ? str('qrContent') : null,
      note: str('note').isNotEmpty ? str('note') : null,
      tuitionPeriod:
          str('tuitionPeriod').isNotEmpty ? str('tuitionPeriod') : null,
      createdAt: str('createdAt').isNotEmpty
          ? str('createdAt')
          : DateTime.now().toIso8601String(),
    );
  }
}
