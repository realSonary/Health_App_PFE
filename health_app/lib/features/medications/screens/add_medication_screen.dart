import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/medication_provider.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _frequency = 'once_daily';
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  bool _isSaving = false;

  final List<String> _frequencies = [
    'once_daily',
    'twice_daily',
    'three_times_daily',
    'four_times_daily',
    'as_needed',
    'weekly',
  ];

  final Map<String, String> _freqLabels = {
    'once_daily': 'Once Daily',
    'twice_daily': 'Twice Daily',
    'three_times_daily': '3× Daily',
    'four_times_daily': '4× Daily',
    'as_needed': 'As Needed',
    'weekly': 'Weekly',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(String freq) {
    setState(() {
      _frequency = freq;
      final count = switch (freq) {
        'twice_daily' => 2,
        'three_times_daily' => 3,
        'four_times_daily' => 4,
        _ => 1,
      };
      _times.clear();
      for (int i = 0; i < count; i++) {
        _times.add(TimeOfDay(hour: 8 + i * 6, minute: 0));
      }
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final medication = Medication(
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      frequency: _frequency,
      scheduleTimes:
          _times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList(),
      startDate: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    final ok = await ref.read(medicationProvider.notifier).add(medication);
    setState(() => _isSaving = false);
    if (ok && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Medication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Medication Name',
                hint: 'e.g., Paracetamol',
                controller: _nameCtrl,
                prefixIcon: Icons.medication_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Dosage',
                hint: 'e.g., 500mg, 1 tablet',
                controller: _dosageCtrl,
                prefixIcon: Icons.scale_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Frequency',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _frequencies.map((f) {
                  final selected = _frequency == f;
                  return GestureDetector(
                    onTap: () => _onFrequencyChanged(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        _freqLabels[f]!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_frequency != 'as_needed') ...[
                const SizedBox(height: 24),
                const Text(
                  'Schedule Times',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_times.length, (i) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _pickTime(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: AppColors.secondary, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Dose ${i + 1}: ${_times[i].format(context)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textHint),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: 'Notes (optional)',
                hint: 'Take with food...',
                controller: _notesCtrl,
                maxLines: 3,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Add Medication',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
