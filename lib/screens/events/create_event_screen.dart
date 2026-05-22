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
import '../../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  final int classroomId;

  const CreateEventScreen({super.key, required this.classroomId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _service = EventService();
  DateTime? _eventTime;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _eventTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventTime ?? now),
    );
    if (t == null) return;
    setState(() =>
        _eventTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn thời gian'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() => _saving = true);
    final r = await _service.createEvent(
      classroomId: widget.classroomId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      eventTime: _eventTime!,
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
      appBar: AppBar(title: const Text('Tạo sự kiện')),
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
                Text('Sự kiện mới', style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Tạo một sự kiện cho lớp. Sinh viên có thể đăng ký tham gia, ban cán sự có thể check-in trong ngày.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.largeSection),
                AppInput(
                  controller: _titleCtrl,
                  label: 'Tên sự kiện *',
                  hint: 'VD: Hoạt động tình nguyện',
                  prefixIcon: const Icon(Icons.event_outlined),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nhập tên sự kiện'
                      : null,
                ),
                const SizedBox(height: AppSpacing.cardPadding),
                AppInput(
                  controller: _descCtrl,
                  label: 'Mô tả (tuỳ chọn)',
                  hint: 'Nội dung, mục tiêu, ghi chú…',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: AppSpacing.cardPadding),
                AppInput(
                  controller: _locationCtrl,
                  label: 'Địa điểm (tuỳ chọn)',
                  hint: 'VD: Hội trường A2',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.cardPadding),
                AppPickerField(
                  label: 'Thời gian *',
                  value: formatDateTime(_eventTime),
                  placeholder: 'Chưa chọn ngày & giờ',
                  prefixIcon: const Icon(Icons.schedule_outlined),
                  suffixIcon: const Icon(Icons.chevron_right),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: AppSpacing.largeSection),
                AppButton(
                  label: 'Tạo sự kiện',
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
