import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input.dart';
import '../../core/widgets/app_picker_field.dart';
import '../../providers/auth_provider.dart';
import '../../services/fund_service.dart';

class CreateCollectionScreen extends StatefulWidget {
  final int classroomId;

  const CreateCollectionScreen({super.key, required this.classroomId});

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _service = FundService();
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d != null) setState(() => _deadline = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() => _saving = true);
    final r = await _service.createCollection(
      classroomId: widget.classroomId,
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      deadline: _deadline,
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
      appBar: AppBar(title: const Text('Tạo đợt thu mới')),
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
                Text('Đợt thu mới', style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Tạo một đợt thu quỹ. Hệ thống sẽ tự sinh khoản đóng cho tất cả thành viên trong lớp.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.largeSection),
                AppInput(
                  controller: _titleCtrl,
                  label: 'Tiêu đề *',
                  hint: 'VD: Quỹ lớp tháng 5',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
                ),
                const SizedBox(height: AppSpacing.cardPadding),
                AppInput(
                  controller: _amountCtrl,
                  label: 'Số tiền (VNĐ) *',
                  hint: 'VD: 50000',
                  prefixIcon: const Icon(Icons.attach_money_outlined),
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
                AppPickerField(
                  label: 'Hạn đóng (tuỳ chọn)',
                  value: formatDate(_deadline),
                  placeholder: 'Chưa chọn',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: const Icon(Icons.chevron_right),
                  onTap: _pickDeadline,
                ),
                const SizedBox(height: AppSpacing.largeSection),
                AppButton(
                  label: 'Tạo đợt thu',
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
