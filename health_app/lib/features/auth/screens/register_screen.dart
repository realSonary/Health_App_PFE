import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 1; // 1, 2, 3

  // Step 1
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // Step 2
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String _gender = 'Female';
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final Set<String> _conditions = {'🫁 Asthma'};
  String _activity = '🚶 Moderate';

  // Step 3
  bool _dataConsent = true;
  bool _reminders = true;
  bool _loading = false;
  String? _error;

  static const _conditionOpts = [
    '🫁 Asthma',
    '💉 Diabetes',
    '🌿 Allergies',
    '❤️ Heart',
    '🩸 Hypertension',
  ];

  static const _activityOpts = ['🛋️ Low', '🚶 Moderate', '🏃 High'];
  static const _genderOpts = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // register() catches all exceptions internally and returns false on failure.
    // We MUST check the return value — it never throws, so a try/catch alone
    // won't catch network or validation failures.
    final success = await ref.read(authProvider.notifier).register(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _nameCtrl.text.trim().isEmpty ? 'New User' : _nameCtrl.text.trim(),
        );

    if (!mounted) return;

    if (!success) {
      // Pull the error message out of authProvider's AuthError state.
      final authState = ref.read(authProvider);
      setState(() {
        _error = authState is AuthError
            ? authState.message
            : 'Registration failed. Please try again.';
        _loading = false;
      });
      return; // stay on the register screen; do NOT navigate
    }

    // Only reach here when registration truly succeeded.
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Text(
                'Step $_step of 3',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(3, (i) {
                  final done = i + 1 <= _step;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color:
                            done ? AppColors.plum700 : AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 1
                    ? _Step1(
                        key: const ValueKey(1),
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        obscure: _obscure,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onNext: () => setState(() => _step = 2),
                        onLogin: () => context.go('/login'),
                      )
                    : _step == 2
                        ? _Step2(
                            key: const ValueKey(2),
                            nameCtrl: _nameCtrl,
                            dobCtrl: _dobCtrl,
                            heightCtrl: _heightCtrl,
                            weightCtrl: _weightCtrl,
                            gender: _gender,
                            onGender: (v) => setState(() => _gender = v),
                            conditions: _conditions,
                            conditionOpts: _conditionOpts,
                            onToggleCondition: (c) {
                              setState(() {
                                if (_conditions.contains(c)) {
                                  _conditions.remove(c);
                                } else {
                                  _conditions.add(c);
                                }
                              });
                            },
                            activity: _activity,
                            activityOpts: _activityOpts,
                            onActivity: (v) =>
                                setState(() => _activity = v),
                            onNext: () => setState(() => _step = 3),
                            onBack: () => setState(() => _step = 1),
                          )
                        : _Step3(
                            key: const ValueKey(3),
                            dataConsent: _dataConsent,
                            reminders: _reminders,
                            onDataConsent: (v) =>
                                setState(() => _dataConsent = v),
                            onReminders: (v) =>
                                setState(() => _reminders = v),
                            loading: _loading,
                            error: _error,
                            onFinish: _finish,
                            onBack: () => setState(() => _step = 2),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 1: Account ─────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onNext;
  final VoidCallback onLogin;

  const _Step1({
    super.key,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onNext,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Create your ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.plum900,
                ),
              ),
              TextSpan(
                text: 'account',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sage600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Start your health journey',
          style: AppTextStyles.caption.copyWith(color: AppColors.neutral400),
        ),
        const SizedBox(height: 24),

        _FieldLabel(label: 'Email address'),
        const SizedBox(height: 6),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'you@hassan2.ma'),
        ),
        const SizedBox(height: 14),

        _FieldLabel(label: 'Password'),
        const SizedBox(height: 6),
        TextField(
          controller: passCtrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '8+ characters',
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.neutral400,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text('Continue →'),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: onLogin,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: 'Already have an account? ',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.neutral500)),
                  TextSpan(
                    text: 'Sign in',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sage600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── Step 2: Health Profile ───────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController dobCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final String gender;
  final ValueChanged<String> onGender;
  final Set<String> conditions;
  final List<String> conditionOpts;
  final ValueChanged<String> onToggleCondition;
  final String activity;
  final List<String> activityOpts;
  final ValueChanged<String> onActivity;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step2({
    super.key,
    required this.nameCtrl,
    required this.dobCtrl,
    required this.heightCtrl,
    required this.weightCtrl,
    required this.gender,
    required this.onGender,
    required this.conditions,
    required this.conditionOpts,
    required this.onToggleCondition,
    required this.activity,
    required this.activityOpts,
    required this.onActivity,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Your health ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.plum900,
                ),
              ),
              TextSpan(
                text: 'profile',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sage600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Personalises your AI analysis',
          style: AppTextStyles.caption.copyWith(color: AppColors.neutral400),
        ),
        const SizedBox(height: 20),

        _FieldLabel(label: 'Full name'),
        const SizedBox(height: 6),
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'Your full name'),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(label: 'Date of birth'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: dobCtrl,
                    decoration:
                        const InputDecoration(hintText: 'DD/MM/YYYY'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(label: 'Gender'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<String>(
                      value: gender,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.neutral800,
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map((g) => DropdownMenuItem(
                              value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => onGender(v!),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(label: 'Height (cm)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '170'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(label: 'Weight (kg)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '65'),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _FieldLabel(label: 'Chronic conditions'),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: conditionOpts.map((c) {
            final isOn = conditions.contains(c);
            return GestureDetector(
              onTap: () => onToggleCondition(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isOn ? AppColors.plum700 : AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        isOn ? AppColors.plum700 : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isOn ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isOn ? Colors.white : AppColors.neutral600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        _FieldLabel(label: 'Activity level'),
        const SizedBox(height: 9),
        Row(
          children: activityOpts.map((a) {
            final isOn = activity == a;
            return Expanded(
              child: GestureDetector(
                onTap: () => onActivity(a),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                      right: activityOpts.indexOf(a) < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isOn ? AppColors.plum700 : AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color:
                          isOn ? AppColors.plum700 : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    a,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isOn ? FontWeight.w600 : FontWeight.w500,
                      color: isOn ? Colors.white : AppColors.neutral600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text('Continue →'),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: onBack,
            child: const Text('← Back'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── Step 3: Consent & Finish ─────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final bool dataConsent;
  final bool reminders;
  final ValueChanged<bool> onDataConsent;
  final ValueChanged<bool> onReminders;
  final bool loading;
  final String? error;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  const _Step3({
    super.key,
    required this.dataConsent,
    required this.reminders,
    required this.onDataConsent,
    required this.onReminders,
    required this.loading,
    this.error,
    required this.onFinish,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Almost ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.plum900,
                ),
              ),
              TextSpan(
                text: 'there!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sage600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Review your preferences',
          style: AppTextStyles.caption.copyWith(color: AppColors.neutral400),
        ),
        const SizedBox(height: 24),

        // Consent toggle
        _ConsentRow(
          emoji: '🔐',
          title: 'Data Privacy',
          sub: 'Encrypted & GDPR compliant',
          value: dataConsent,
          onChanged: onDataConsent,
        ),
        const SizedBox(height: 12),
        _ConsentRow(
          emoji: '🔔',
          title: 'Health Reminders',
          sub: 'Water, medication & sleep alerts',
          value: reminders,
          onChanged: onReminders,
        ),

        const SizedBox(height: 24),

        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.rose50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.rose200),
            ),
            child: Text(
              error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.rose700),
            ),
          ),
          const SizedBox(height: 14),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sage600,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Create Account ✨'),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: onBack,
            child: const Text('← Back'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ConsentRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConsentRow({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.sage100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodySemiBold),
                Text(sub, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.plum700,
          ),
        ],
      ),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.label);
  }
}
