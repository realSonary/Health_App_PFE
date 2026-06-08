import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/health_card.dart';
import '../providers/medication_provider.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() =>
      _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(medicationProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medications'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => context.push('/add-medication'),
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(44, 44),
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.medications.isEmpty
              ? _buildEmptyState(context)
              : _buildMedicationList(state),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.light.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_outlined,
                  size: 38, color: AppColors.secondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No medications yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your medications to track doses and get reminders.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push('/add-medication'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Medication'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationList(MedicationState state) {
    final active = state.medications.where((m) => m.isActive).toList();
    final inactive = state.medications.where((m) => !m.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active.isNotEmpty) ...[
            const SectionHeader(title: 'Active'),
            const SizedBox(height: 12),
            ...active.asMap().entries.map((e) => _MedicationCard(
                  medication: e.value,
                  onDelete: () => ref
                      .read(medicationProvider.notifier)
                      .delete(e.value.id!),
                  onMarkTaken: () => ref
                      .read(medicationProvider.notifier)
                      .markTaken(e.value.id!, DateTime.now()),
                ).animate().fadeIn(delay: (e.key * 60).ms)),
          ],
          if (inactive.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: 'Inactive'),
            const SizedBox(height: 12),
            ...inactive.asMap().entries.map((e) => _MedicationCard(
                  medication: e.value,
                  isInactive: true,
                  onDelete: () => ref
                      .read(medicationProvider.notifier)
                      .delete(e.value.id!),
                  onMarkTaken: null,
                ).animate().fadeIn(delay: (e.key * 60).ms)),
          ],
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onDelete;
  final VoidCallback? onMarkTaken;
  final bool isInactive;

  const _MedicationCard({
    required this.medication,
    required this.onDelete,
    this.onMarkTaken,
    this.isInactive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isInactive ? AppColors.textHint : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isInactive
                      ? AppColors.surface
                      : AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isInactive
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${medication.dosage} · ${medication.frequencyLabel}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.textHint, size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'delete') {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('Remove Medication'),
                        content: Text(
                            'Remove ${medication.name} from your list?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete();
                            },
                            child: const Text('Remove',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'delete', child: Text('Remove')),
                ],
              ),
            ],
          ),

          if (medication.scheduleTimes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: medication.scheduleTimes.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        t,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          if (onMarkTaken != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: medication.isTaken
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FBF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Color(0xFF16A34A), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Taken Today ✓',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: onMarkTaken,
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 16),
                      label: const Text('Mark as Taken'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(
                            color: AppColors.secondary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
