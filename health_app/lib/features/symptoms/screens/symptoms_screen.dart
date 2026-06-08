import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/symptoms_provider.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class SymptomsScreen extends ConsumerStatefulWidget {
  const SymptomsScreen({super.key});

  @override
  ConsumerState<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> _filtered(List<String> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(symptomsProvider);
    final notifier = ref.read(symptomsProvider.notifier);
    final filtered = _filtered(state.allSymptoms);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Fixed header ────────────────────────────────────────────────
          Container(
            color: AppColors.card,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'Symptom ',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.plum900,
                                ),
                              ),
                              TextSpan(
                                text: 'Check',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.plum500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        if (state.selected.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              notifier.clearAll();
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Text(
                              'Clear all',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.rose600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Text(
                      'Select your symptoms — we\'ll match potential conditions',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.neutral500),
                    ),
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.neutral700,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search symptoms...',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 14, right: 8),
                            child:
                                Text('🔍', style: TextStyle(fontSize: 15)),
                          ),
                          prefixIconConstraints:
                              BoxConstraints(minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  // Selected count bar
                  if (state.selected.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.plum50,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Text(
                        '${state.selected.length} symptom${state.selected.length > 1 ? 's' : ''} selected',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.plum700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Divider(height: 1),
                ],
              ),
            ),
          ),

          // ── Scrollable body ─────────────────────────────────────────────
          Expanded(
            child: state.kbLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.plum700))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Symptom chips
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: filtered.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'No symptoms match "$_searchQuery"',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.neutral400),
                                    ),
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: filtered.map((sym) {
                                    final isOn = state.isSelected(sym);
                                    return _SymptomChip(
                                      label: sym,
                                      isSelected: isOn,
                                      onTap: () =>
                                          notifier.toggleSymptom(sym),
                                    );
                                  }).toList(),
                                ),
                        ).animate().fadeIn(duration: 300.ms),

                        // Analyse button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.selected.isEmpty
                                  ? null
                                  : notifier.analyse,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.plum700,
                                disabledBackgroundColor: AppColors.neutral200,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Text('🔍',
                                      style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Analyse Symptoms',
                                    style: AppTextStyles.bodySemiBold
                                        .copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Results
                        if (state.analysed) ...[
                          const SizedBox(height: 20),
                          if (state.matches.isEmpty)
                            _NoMatchCard()
                          else
                            _ResultsSection(matches: state.matches),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Symptom chip ─────────────────────────────────────────────────────────────

class _SymptomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SymptomChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.plum700 : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.plum700 : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.plum700.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.neutral600,
          ),
        ),
      ),
    );
  }
}

// ─── No-match card ────────────────────────────────────────────────────────────

class _NoMatchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: cardDecoration(),
        child: Column(
          children: [
            const Text('🤔', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('No strong matches found',
                style: AppTextStyles.bodySemiBold),
            const SizedBox(height: 6),
            Text(
              'Try selecting more symptoms for a better match.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.neutral400),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ─── Results section ──────────────────────────────────────────────────────────

class _ResultsSection extends StatelessWidget {
  final List<DiseaseMatch> matches;
  const _ResultsSection({required this.matches});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.plum900, AppColors.plum700],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child:
                      const Text('🔬', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Possible Conditions',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Matched from 100 conditions · ${matches.length} result${matches.length > 1 ? 's' : ''} found',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Match cards
          Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ...matches.asMap().entries.map((e) {
                  final isLast = e.key == matches.length - 1;
                  return _MatchRow(
                    match: e.value,
                    rank: e.key + 1,
                    isLast: isLast,
                  );
                }),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.rose50,
                    border: const Border(
                        top: BorderSide(color: AppColors.rose200)),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Not a medical diagnosis. Always consult a qualified healthcare professional.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.rose600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

// ─── Individual match row ─────────────────────────────────────────────────────

class _MatchRow extends StatefulWidget {
  final DiseaseMatch match;
  final int rank;
  final bool isLast;

  const _MatchRow({
    required this.match,
    required this.rank,
    required this.isLast,
  });

  @override
  State<_MatchRow> createState() => _MatchRowState();
}

class _MatchRowState extends State<_MatchRow> {
  bool _expanded = false;

  Color get _rankColor {
    if (widget.rank == 1) return AppColors.plum700;
    if (widget.rank == 2) return AppColors.plum500;
    if (widget.rank == 3) return AppColors.plum400;
    return AppColors.neutral400;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.match.disease;
    final pct = widget.match.pct;
    final matchCount = widget.match.matchCount;
    final total = widget.match.totalSymptoms;

    return Container(
      decoration: BoxDecoration(
        border: widget.isLast && !_expanded
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row — tap to expand
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _rankColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${widget.rank}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _rankColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _capitalize(d.name),
                          style: AppTextStyles.bodySemiBold,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$pct%',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _rankColor,
                            ),
                          ),
                          Text(
                            '$matchCount/$total symptoms',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.neutral400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.neutral400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Match bar
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (pct / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _rankColor.withOpacity(0.5),
                                _rankColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail panel
          if (_expanded)
            _DetailPanel(disease: d)
                .animate()
                .fadeIn(duration: 220.ms)
                .slideY(begin: -0.02, end: 0),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Detail panel ─────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final DiseaseInfo disease;
  const _DetailPanel({required this.disease});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (disease.description.isNotEmpty) ...[
            _SectionLabel(emoji: '📋', label: 'About'),
            const SizedBox(height: 6),
            Text(
              disease.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.neutral700,
                height: 1.5,
                fontSize: 12.5,
              ),
            ),
          ],

          // Precautions
          if (disease.precautions.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionLabel(emoji: '🛡️', label: 'Precautions'),
            const SizedBox(height: 6),
            ...disease.precautions.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.sage600,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.neutral700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Diet
          if (disease.diet.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionLabel(emoji: '🥗', label: 'Recommended Diet'),
            const SizedBox(height: 6),
            ...disease.diet.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.plum500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.neutral700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String emoji;
  final String label;
  const _SectionLabel({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.plum800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
