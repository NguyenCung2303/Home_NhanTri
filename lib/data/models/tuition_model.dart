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
      createdAt: map['created_at'],
    );
  }
}