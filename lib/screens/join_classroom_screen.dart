import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_input.dart';
import '../providers/auth_provider.dart';
import '../services/classroom_service.dart';

class JoinClassroomScreen extends StatefulWidget {
  const JoinClassroomScreen({super.key});

  @override
  State<JoinClassroomScreen> createState() => _JoinClassroomScreenState();
}

class _JoinClassroomScreenState extends State<JoinClassroomScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _classroomService = ClassroomService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    final result = await _classroomService.joinClassroom(
      _codeController.text.trim().toUpperCase(),
      userId!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      final data = result['data'];
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tham gia thành công'),
          content: Text(
            'Bạn đã tham gia lớp ${data['className']} với vai trò ${data['role']}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
      appBar: AppBar(title: const Text('Tham gia lớp học')),
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
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.group_add_outlined,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.cardPadding),
                Text(
                  'Nhập mã tham gia',
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Nhận mã từ ban cán sự lớp',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.largeVertical),
                AppInput(
                  controller: _codeController,
                  hint: 'VD: X7A9KQ',
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  textStyle: AppTextStyles.heading.copyWith(letterSpacing: 6),
                  onSubmitted: (_) => _join(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nhập mã tham gia' : null,
                ),
                const SizedBox(height: AppSpacing.largeSection),
                AppButton(
                  label: 'Tham gia',
                  size: AppButtonSize.large,
                  loading: _isLoading,
                  onPressed: _isLoading ? null : _join,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
