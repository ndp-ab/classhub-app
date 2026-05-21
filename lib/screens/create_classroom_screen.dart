import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_input.dart';
import '../providers/auth_provider.dart';
import '../services/classroom_service.dart';

class CreateClassroomScreen extends StatefulWidget {
  const CreateClassroomScreen({super.key});

  @override
  State<CreateClassroomScreen> createState() => _CreateClassroomScreenState();
}

class _CreateClassroomScreenState extends State<CreateClassroomScreen> {
  final _classNameController = TextEditingController();
  final _facultyController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _classroomService = ClassroomService();
  bool _isLoading = false;
  String? _inviteCode;

  @override
  void dispose() {
    _classNameController.dispose();
    _facultyController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    final result = await _classroomService.createClassroom(
      _classNameController.text.trim(),
      _facultyController.text.trim(),
      _academicYearController.text.trim(),
      userId!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() => _inviteCode = result['data']['inviteCode']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo lớp học mới')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.largeSection,
          ),
          child: _inviteCode != null ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Thông tin lớp', style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.small),
          Text(
            'Điền thông tin để tạo lớp học mới. Hệ thống sẽ sinh mã mời để bạn chia sẻ.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.largeSection),
          AppInput(
            controller: _classNameController,
            label: 'Tên lớp',
            hint: 'VD: 64KTPM3',
            prefixIcon: const Icon(Icons.class_outlined),
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || v.isEmpty ? 'Nhập tên lớp' : null,
          ),
          const SizedBox(height: AppSpacing.cardPadding),
          AppInput(
            controller: _facultyController,
            label: 'Khoa',
            hint: 'VD: Công nghệ thông tin',
            prefixIcon: const Icon(Icons.business_outlined),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.cardPadding),
          AppInput(
            controller: _academicYearController,
            label: 'Khóa',
            hint: 'VD: K64',
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: AppSpacing.largeSection),
          AppButton(
            label: 'Tạo lớp',
            size: AppButtonSize.large,
            loading: _isLoading,
            onPressed: _isLoading ? null : _create,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 36,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.cardPadding),
        Text(
          'Tạo lớp thành công',
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'Chia sẻ mã mời dưới đây với sinh viên để tham gia lớp.',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.largeSection),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sectionPadding,
            vertical: AppSpacing.largeSection,
          ),
          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
          borderColor: AppColors.primary.withValues(alpha: 0.2),
          child: Column(
            children: [
              Text(
                'MÃ THAM GIA',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                _inviteCode!,
                style: AppTextStyles.display.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardPadding),
        AppButton(
          label: 'Sao chép mã',
          icon: Icons.copy_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _inviteCode!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã copy mã tham gia')),
            );
          },
        ),
        const SizedBox(height: AppSpacing.element),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quay về trang chủ'),
          ),
        ),
      ],
    );
  }
}
