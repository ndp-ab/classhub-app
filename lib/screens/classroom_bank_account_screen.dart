import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_error_state.dart';
import '../core/widgets/app_input.dart';
import '../core/widgets/app_loading.dart';
import '../models/classroom_bank_account.dart';
import '../services/classroom_service.dart';

class ClassroomBankAccountScreen extends StatefulWidget {
  const ClassroomBankAccountScreen({super.key, required this.classroomId});

  final int classroomId;

  @override
  State<ClassroomBankAccountScreen> createState() =>
      _ClassroomBankAccountScreenState();
}

class _ClassroomBankAccountScreenState
    extends State<ClassroomBankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameCtrl = TextEditingController();
  final _bankBinCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _service = ClassroomService();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBankAccount();
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _bankBinCtrl.dispose();
    _accountNoCtrl.dispose();
    _accountNameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccount() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.getBankAccount(widget.classroomId);
    if (!mounted) return;

    if (result['success'] == true) {
      _fillForm(result['data'] as ClassroomBankAccount);
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = false;
      _error = result['notConfigured'] == true
          ? null
          : result['message']?.toString() ?? 'Không tải được tài khoản';
    });
  }

  void _fillForm(ClassroomBankAccount account) {
    _bankNameCtrl.text = account.bankName;
    _bankBinCtrl.text = account.bankBin;
    _accountNoCtrl.text = account.accountNo;
    _accountNameCtrl.text = account.accountName;
    _noteCtrl.text = account.note ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đổi tài khoản nhận tiền?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin này ảnh hưởng đến TẤT CẢ khoản thu sau này.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text('Vui lòng kiểm tra kỹ:',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Ngân hàng: ${_bankNameCtrl.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Số tài khoản: ${_accountNoCtrl.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Chủ tài khoản: ${_accountNameCtrl.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kiểm tra lại'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận lưu'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final result = await _service.updateBankAccount(
      classroomId: widget.classroomId,
      bankBin: _bankBinCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      accountNo: _accountNoCtrl.text.trim(),
      accountName: _accountNameCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Lưu thất bại'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản nhận tiền')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoading(message: 'Đang tải tài khoản nhận tiền');
    }

    if (_error != null) {
      return AppErrorState(
        title: 'Không tải được tài khoản',
        message: _error,
        onRetry: _loadBankAccount,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.largeSection,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tài khoản nhận tiền', style: AppTextStyles.heading),
            const SizedBox(height: AppSpacing.small),
            Text(
              'Thông tin này được dùng để sinh VietQR cho các khoản thu của lớp.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.largeSection),
            AppInput(
              controller: _bankNameCtrl,
              label: 'Tên ngân hàng *',
              hint: 'VD: MB Bank',
              prefixIcon: const Icon(Icons.account_balance_outlined),
              textInputAction: TextInputAction.next,
              validator: (v) => _required(v, 'Nhập tên ngân hàng'),
            ),
            const SizedBox(height: AppSpacing.cardPadding),
            AppInput(
              controller: _bankBinCtrl,
              label: 'Bank BIN *',
              hint: 'VD: 970422',
              prefixIcon: const Icon(Icons.tag_outlined),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => _required(v, 'Nhập Bank BIN'),
            ),
            const SizedBox(height: AppSpacing.cardPadding),
            AppInput(
              controller: _accountNoCtrl,
              label: 'Số tài khoản *',
              hint: 'VD: 0123456789',
              prefixIcon: const Icon(Icons.credit_card_outlined),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => _required(v, 'Nhập số tài khoản'),
            ),
            const SizedBox(height: AppSpacing.cardPadding),
            AppInput(
              controller: _accountNameCtrl,
              label: 'Tên chủ tài khoản *',
              hint: 'VD: NGUYEN VAN A',
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => _required(v, 'Nhập tên chủ tài khoản'),
            ),
            const SizedBox(height: AppSpacing.cardPadding),
            AppInput(
              controller: _noteCtrl,
              label: 'Ghi chú',
              hint: 'VD: Đổi thủ quỹ',
              prefixIcon: const Icon(Icons.notes_outlined),
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.largeSection),
            AppButton(
              label: 'Lưu tài khoản',
              icon: Icons.save_outlined,
              size: AppButtonSize.large,
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
