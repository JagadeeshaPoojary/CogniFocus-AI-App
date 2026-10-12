import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/clay_colors.dart';
import '../../models/classroom_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_status_badge.dart';

/// ClassroomsScreen: Directory of Authorized Classrooms
class ClassroomsScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const ClassroomsScreen({super.key, this.onNavigateTab});

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherProvider>().fetchClassrooms();
    });
  }

  Future<void> _handleEnterClassroom(ClassroomModel classroom) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isTeacher) {
      try {
        await authProvider.enterClassroom(
          classroom.code.isNotEmpty ? classroom.code : classroom.id,
        );
        if (mounted) {
          await context.read<TeacherProvider>().refreshAll();
          widget.onNavigateTab?.call(2); // Go to Live Stream
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enter classroom: $e'),
              backgroundColor: ClayColors.softCoral,
            ),
          );
        }
      }
    } else {
      widget.onNavigateTab?.call(2); // Go to Live Stream
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final teacherProvider = context.watch<TeacherProvider>();
    final classrooms = teacherProvider.classrooms;

    final palette = ClayColors.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: 'Classrooms',
            subtitle: authProvider.isAdmin
                ? 'All System Educational Halls'
                : 'Your Authorized Classrooms',
            onRefresh: () => teacherProvider.fetchClassrooms(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: palette.primaryBlue,
              onRefresh: () => teacherProvider.fetchClassrooms(),
              child: teacherProvider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.primaryBlue,
                        ),
                      ),
                    )
                  : classrooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 48,
                            color: palette.textLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No classrooms assigned to this account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: classrooms.length,
                      itemBuilder: (ctx, index) {
                        final cls = classrooms[index];
                        final isActive =
                            authProvider.activeClassroom?.id == cls.id ||
                            authProvider.activeClassroom?.code == cls.code ||
                            cls.isActive;

                        return ClayCard(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: isActive
                              ? ClayColors.clayMint
                              : ClayColors.clayWhite,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? palette.success
                                              : palette.primaryBlue,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          cls.code.isNotEmpty
                                              ? cls.code
                                              : cls.id,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cls.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'ID: ${cls.id}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: palette.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (isActive)
                                    ClayStatusBadge.active()
                                  else
                                    ClayStatusBadge(
                                      label: 'READY',
                                      backgroundColor: palette.canvasDark,
                                      textColor: palette.textSecondary,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Pill Metadata Row
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildMetaPill(
                                    icon: Icons.people_outline_rounded,
                                    label: '${cls.studentsCount} Students',
                                    color: palette.primaryBlue,
                                  ),
                                  _buildMetaPill(
                                    icon: Icons.videocam_outlined,
                                    label:
                                        cls.id == 'CSE-301' ||
                                            cls.code == 'CSE301'
                                        ? 'CAM001, CAM002'
                                        : 'CAM003, CAM004',
                                    color: palette.success,
                                  ),
                                  _buildMetaPill(
                                    icon: Icons.warning_amber_rounded,
                                    label: '${cls.totalAlerts} Alerts',
                                    color: palette.error,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Action Button
                              ClayButton(
                                text: isActive
                                    ? 'View Live Camera Stream'
                                    : 'Enter & Start Monitoring',
                                icon: isActive
                                    ? Icons.videocam_rounded
                                    : Icons.login_rounded,
                                color: isActive
                                    ? palette.primaryBlue
                                    : palette.success,
                                height: 44,
                                onPressed: () => _handleEnterClassroom(cls),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
