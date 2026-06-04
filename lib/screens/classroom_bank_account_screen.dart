import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/vietnam_banks.dart';
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
  final _accountNoCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _service = ClassroomService();

  BankItem? _selectedBank;
  String? _unknownBankName; // Lưu tên ngân hàng từ BE nếu không match
  
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
    // Tìm ngân hàng trong list local bằng bankBin
    final matchedBank = vietnameseBanks.firstWhere(
      (bank) => bank.bankBin == account.bankBin,
      orElse: () => vietnameseBanks.firstWhere(
        (bank) => bank.bankName == account.bankName || bank.shortName == account.bankName,
        orElse: () => const BankItem(bankName: '', shortName: '', bankBin: ''),
      ),
    );

    if (matchedBank.bankBin.isNotEmpty) {
      // Match found
      _selectedBank = matchedBank;
      _unknownBankName = null;
    } else {
      // Không match - lưu lại để hiển thị warning
      _selectedBank = null;
      _unknownBankName = account.bankName;
    }

    _accountNoCtrl.text = account.accountNo;
    _accountNameCtrl.text = account.accountName;
    _noteCtrl.text = account.note ?? '';
  }

  Future<void> _submit() async {
    // Chống double-tap: nếu đang lưu thì bỏ qua
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    // Capture trước khi vào vùng async để tránh race condition
    final bank = _selectedBank;

    // Validation: Must select a bank
    if (bank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngân hàng từ danh sách'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog — dùng local var `bank`, không dùng _selectedBank!
    final noteText = _noteCtrl.text.trim();
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
            Text('Ngân hàng: ${bank.shortName}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Số tài khoản: ${_accountNoCtrl.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Chủ tài khoản: ${_accountNameCtrl.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (noteText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Ghi chú: $noteText',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
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
    // Dùng local var `bank` — an toàn dù _selectedBank thay đổi sau await
    final result = await _service.updateBankAccount(
      classroomId: widget.classroomId,
      bankBin: bank.bankBin,
      bankName: bank.bankName,
      accountNo: _accountNoCtrl.text.trim(),
      accountName: _accountNameCtrl.text.trim(),
      note: noteText,
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

  Widget _buildBankSelector() {
    return InkWell(
      onTap: _showBankPicker,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngân hàng *',
          prefixIcon: const Icon(Icons.account_balance_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: _selectedBank != null
            ? Text(_selectedBank!.shortName, style: const TextStyle(fontSize: 16))
            : _unknownBankName != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_unknownBankName!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text(
                        'Vui lòng chọn lại ngân hàng từ danh sách',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  )
                : const Text(
                    'Chọn ngân hàng',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
      ),
    );
  }

  Future<void> _showBankPicker() async {
    final selected = await showModalBottomSheet<BankItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BankPickerBottomSheet(
        currentBank: _selectedBank,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedBank = selected;
        _unknownBankName = null;
      });
    }
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
            _buildBankSelector(),
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


// Bottom Sheet for Bank Selection
class _BankPickerBottomSheet extends StatefulWidget {
  final BankItem? currentBank;

  const _BankPickerBottomSheet({this.currentBank});

  @override
  State<_BankPickerBottomSheet> createState() => _BankPickerBottomSheetState();
}

class _BankPickerBottomSheetState extends State<_BankPickerBottomSheet> {
  final _searchCtrl = TextEditingController();
  List<BankItem> _filteredBanks = vietnameseBanks;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterBanks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = vietnameseBanks;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredBanks = vietnameseBanks.where((bank) {
          return bank.shortName.toLowerCase().contains(lowerQuery) ||
              bank.bankName.toLowerCase().contains(lowerQuery) ||
              bank.bankBin.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Chọn ngân hàng',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _filterBanks,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm ngân hàng...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _filterBanks('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Bank list
            Expanded(
              child: _filteredBanks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Không tìm thấy ngân hàng', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredBanks.length,
                      itemBuilder: (context, index) {
                        final bank = _filteredBanks[index];
                        final isSelected = widget.currentBank?.bankBin == bank.bankBin;
                        return ListTile(
                          leading: const Icon(Icons.account_balance),
                          title: Text(bank.shortName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(bank.bankName, style: const TextStyle(fontSize: 12)),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary)
                              : null,
                          selected: isSelected,
                          onTap: () => Navigator.pop(context, bank),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
