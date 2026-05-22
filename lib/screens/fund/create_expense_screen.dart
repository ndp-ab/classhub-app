import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input.dart';
import '../../providers/auth_provider.dart';
import '../../services/fund_service.dart';

class CreateExpenseScreen extends StatefulWidget {
  final int classroomId;

  const CreateExpenseScreen({super.key, required this.classroomId});

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _service = FundService();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() => _saving = true);
    final r = await _service.createExpense(
      classroomId: widget.classroomId,
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      reason: _reasonCtrl.text.trim(),
      userId: userId,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (r['success']) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r['message'] ?? 'Tạo thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm khoản chi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.largeSection,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Khoản chi mới', style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Ghi nhận một khoản đã chi từ quỹ lớp. Thông tin này sẽ hiện trong tab Khoản chi cho mọi thành viên.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.largeSection),
                AppInput(
                  controller: _titleCtrl,
                  label: 'Tiêu đề *',
                  hint: 'VD: Mua nước cho buổi liên hoan',
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
                ),
                const SizedBox(height: AppSpacing.cardPadding),
                AppInput(
                  controller: _amountCtrl,
                  label: 'Số tiền (VNĐ) *',
                  hint: 'VD: 100000',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nhập số tiền';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Số tiền phải > 0';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.cardPadding),
                AppInput(
                  controller: _reasonCtrl,
                  label: 'Lý do (tuỳ chọn)',
                  hint: 'Mô tả ngắn lý do chi…',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: AppSpacing.largeSection),
                AppButton(
                  label: 'Thêm khoản chi',
                  size: AppButtonSize.large,
                  loading: _saving,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
