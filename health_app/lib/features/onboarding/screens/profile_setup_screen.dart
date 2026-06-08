import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  // State
  String _gender = 'male';
  String? _bloodType;
  DateTime? _dob;
  final Set<String> _selectedConditions = {};
  bool _isSaving = false;

  final List<String> _genders = ['male', 'female', 'other'];
  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobCtrl.text = DateFormat('MMMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final profile = ProfileModel(
      userId: 0,
      fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      weightKg: double.tryParse(_weightCtrl.text),
      heightCm: double.tryParse(_heightCtrl.text),
      bloodType: _bloodType,
      medicalConditions: _selectedConditions.toList(),
    );
    await ref.read(profileProvider.notifier).saveProfile(profile);
    setState(() => _isSaving = false);
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _prevPage,
              )
            : null,
        actions: [
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _currentPage
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _currentPage = p),
              children: [
                _buildPage1(),
                _buildPage2(),
                _buildPage3(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
            child: GradientButton(
              label: _currentPage < 2 ? 'Continue' : 'Finish Setup',
              isLoading: _isSaving,
              onPressed: _nextPage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Info',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us a bit about yourself',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 36),
          AppTextField(
            label: 'Full Name',
            hint: 'Your name',
            controller: _nameCtrl,
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Date of Birth',
            hint: 'Select date',
            controller: _dobCtrl,
            readOnly: true,
            onTap: _pickDob,
            prefixIcon: Icons.cake_outlined,
            suffixWidget:
                const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _genders.map((g) {
              final selected = _gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                        right: g != _genders.last ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        g[0].toUpperCase() + g.substring(1),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body Metrics',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Used to calculate your health score',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Weight',
                  hint: 'kg',
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.monitor_weight_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}'))
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppTextField(
                  label: 'Height',
                  hint: 'cm',
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.height_rounded,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Blood Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _bloodTypes.map((bt) {
              final selected = _bloodType == bt;
              return GestureDetector(
                onTap: () =>
                    setState(() => _bloodType = selected ? null : bt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    bt,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical History',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select any existing conditions',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppConstants.medicalConditions.map((cond) {
              final selected = _selectedConditions.contains(cond);
              return GestureDetector(
                onTap: () => setState(() {
                  if (cond == 'None') {
                    _selectedConditions.clear();
                    _selectedConditions.add('None');
                  } else {
                    _selectedConditions.remove('None');
                    if (selected) {
                      _selectedConditions.remove(cond);
                    } else {
                      _selectedConditions.add(cond);
                    }
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
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
                    cond,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
