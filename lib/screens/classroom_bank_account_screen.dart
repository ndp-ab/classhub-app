import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/app_error_state.dart';
import '../core/widgets/app_input.dart';
import '../core/widgets/app_loading.dart';
import '../models/bank.dart';
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

  Bank? _selectedBank;
  ClassroomBankAccount? _currentAccount;
  List<Bank> _banks = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _banksError;

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
      _banksError = null;
    });

    final banksResult = await _service.getBanks();
    final accountResult = await _service.getBankAccount(widget.classroomId);
    if (!mounted) return;

    final banks = banksResult['success'] == true
        ? (banksResult['data'] as List).cast<Bank>()
        : <Bank>[];
    final banksError = banksResult['success'] == true
        ? null
        : banksResult['message']?.toString() ??
              'Không tải được danh sách ngân hàng';

    ClassroomBankAccount? account;
    Bank? selectedBank;
    String? accountError;

    if (accountResult['success'] == true) {
      account = accountResult['data'] as ClassroomBankAccount;
      _fillForm(account);
      selectedBank = _findBank(banks, account);
    } else if (accountResult['notConfigured'] != true) {
      accountError =
          accountResult['message']?.toString() ?? 'Không tải được tài khoản';
    }

    setState(() {
      _loading = false;
      _banks = banks;
      _banksError = banksError;
      _currentAccount = account;
      _selectedBank = selectedBank;
      _error = accountError;
    });
  }

  void _fillForm(ClassroomBankAccount account) {
    _accountNoCtrl.text = account.accountNo;
    _accountNameCtrl.text = account.accountName;
    _noteCtrl.text = account.note ?? '';
  }

  Bank? _findBank(List<Bank> banks, ClassroomBankAccount account) {
    for (final bank in banks) {
      if (bank.bankBin == account.bankBin) return bank;
    }
    for (final bank in banks) {
      if (bank.name == account.bankName ||
          bank.shortName == account.shortName ||
          bank.shortName == account.bankName) {
        return bank;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _loadBanksForPicker() {
    return _service.getBanks();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final bank = _selectedBank;
    if (bank == null || bank.bankBin.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngân hàng từ danh sách'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
            const Text(
              'Vui lòng kiểm tra kỹ:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Ngân hàng: ${bank.displayName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Số tài khoản: ${_accountNoCtrl.text.trim()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Chủ tài khoản: ${_accountNameCtrl.text.trim()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (noteText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Ghi chú: $noteText',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
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
    final result = await _service.updateBankAccount(
      classroomId: widget.classroomId,
      bankBin: bank.bankBin,
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
    final snapshotName = _currentAccount?.displayBankName.trim();

    return InkWell(
      onTap: _showBankPicker,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngân hàng *',
          prefixIcon: const Icon(Icons.account_balance_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        child: _selectedBank != null
            ? Text(_selectedBank!.displayName, style: AppTextStyles.body)
            : snapshotName != null && snapshotName.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshotName, style: AppTextStyles.body),
                  const SizedBox(height: AppSpacing.tiny),
                  Text(
                    'Chọn lại ngân hàng từ danh sách để cập nhật.',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              )
            : Text(
                _banksError == null
                    ? 'Chọn ngân hàng'
                    : 'Không tải được danh sách ngân hàng',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }

  Future<void> _showBankPicker() async {
    final selected = await showModalBottomSheet<Bank>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BankPickerBottomSheet(
        currentBank: _selectedBank,
        initialBanks: _banks,
        initialError: _banksError,
        loadBanks: _loadBanksForPicker,
      ),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedBank = selected;
      _banksError = null;
      if (!_banks.any((bank) => bank.bankBin == selected.bankBin)) {
        _banks = [..._banks, selected];
      }
    });
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
              hint: 'Nhập số tài khoản',
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
              hint: 'Nhập tên chủ tài khoản',
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => _required(v, 'Nhập tên chủ tài khoản'),
            ),
            const SizedBox(height: AppSpacing.cardPadding),
            AppInput(
              controller: _noteCtrl,
              label: 'Ghi chú',
              hint: 'Nhập ghi chú nếu cần',
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

class _BankPickerBottomSheet extends StatefulWidget {
  const _BankPickerBottomSheet({
    required this.initialBanks,
    required this.loadBanks,
    this.currentBank,
    this.initialError,
  });

  final Bank? currentBank;
  final List<Bank> initialBanks;
  final String? initialError;
  final Future<Map<String, dynamic>> Function() loadBanks;

  @override
  State<_BankPickerBottomSheet> createState() => _BankPickerBottomSheetState();
}

class _BankPickerBottomSheetState extends State<_BankPickerBottomSheet> {
  final _searchCtrl = TextEditingController();
  late List<Bank> _banks;
  late List<Bank> _filteredBanks;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _banks = widget.initialBanks;
    _filteredBanks = widget.initialBanks;
    _error = widget.initialError;
    if (_banks.isEmpty && _error == null) {
      _loadBanks();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.loadBanks();
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _banks = (result['data'] as List).cast<Bank>();
        _filteredBanks = _filter(_searchCtrl.text);
      } else {
        _banks = [];
        _filteredBanks = [];
        _error =
            result['message']?.toString() ??
            'Không tải được danh sách ngân hàng';
      }
    });
  }

  List<Bank> _filter(String query) {
    final lowerQuery = query.trim().toLowerCase();
    if (lowerQuery.isEmpty) return _banks;

    return _banks.where((bank) {
      return bank.displayName.toLowerCase().contains(lowerQuery) ||
          bank.name.toLowerCase().contains(lowerQuery) ||
          bank.code.toLowerCase().contains(lowerQuery) ||
          bank.bankBin.contains(query.trim());
    }).toList();
  }

  void _filterBanks(String query) {
    setState(() => _filteredBanks = _filter(query));
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    enabled: !_loading && _error == null && _banks.isNotEmpty,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBankList(scrollController)),
          ],
        );
      },
    );
  }

  Widget _buildBankList(ScrollController scrollController) {
    if (_loading) {
      return const AppLoading(message: 'Đang tải danh sách ngân hàng');
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.largeSection),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.cardPadding),
              AppButton(
                label: 'Thử lại',
                icon: Icons.refresh,
                variant: AppButtonVariant.secondary,
                fullWidth: false,
                onPressed: _loadBanks,
              ),
            ],
          ),
        ),
      );
    }

    if (_banks.isEmpty) {
      return AppEmptyState(
        icon: Icons.account_balance_outlined,
        title: 'Chưa có ngân hàng',
        message: 'Danh mục ngân hàng chưa có dữ liệu.',
        actionLabel: 'Thử lại',
        onAction: () {
          _loadBanks();
        },
      );
    }

    if (_filteredBanks.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off,
        title: 'Không tìm thấy ngân hàng',
        message: 'Thử tìm theo tên ngắn, tên đầy đủ, mã hoặc BIN.',
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: _filteredBanks.length,
      itemBuilder: (context, index) {
        final bank = _filteredBanks[index];
        final isSelected = widget.currentBank?.bankBin == bank.bankBin;
        final subtitle =
            bank.name.trim().isNotEmpty && bank.name.trim() != bank.displayName
            ? bank.name
            : bank.bankBin;

        return ListTile(
          leading: const Icon(Icons.account_balance),
          title: Text(
            bank.displayName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppColors.primary)
              : null,
          selected: isSelected,
          onTap: () => Navigator.pop(context, bank),
        );
      },
    );
  }
}
