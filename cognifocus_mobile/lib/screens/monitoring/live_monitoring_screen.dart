import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/clay_colors.dart';
import '../../core/theme/clay_styles.dart';
import '../../models/camera_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/camera_player.dart';
import '../../widgets/clay_card.dart';

/// LiveMonitoringScreen: Real-time Multi-Camera AI Video Stream
class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> {
  String _selectedCameraId = 'CAM001';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCameras();
    });
  }

  void _loadCameras() {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin) {
      context.read<AdminProvider>().fetchAdminData();
    } else {
      context.read<TeacherProvider>().fetchCameras();
    }
  }

  List<CameraModel> _getCameras(
    AuthProvider auth,
    AdminProvider admin,
    TeacherProvider teacher,
  ) {
    if (auth.isAdmin) {
      return admin.cameras.isNotEmpty
          ? admin.cameras
          : [
              const CameraModel(
                id: 'CAM001',
                name: 'Classroom 301 Front',
                status: 'online',
              ),
              const CameraModel(
                id: 'CAM002',
                name: 'Classroom 301 Rear',
                status: 'online',
              ),
              const CameraModel(
                id: 'CAM003',
                name: 'Classroom 302 Front',
                status: 'online',
              ),
              const CameraModel(
                id: 'CAM004',
                name: 'Classroom 302 Rear',
                status: 'online',
              ),
            ];
    } else {
      if (teacher.cameras.isNotEmpty) {
        return teacher.cameras;
      }
      final is302 =
          auth.activeClassroom?.id == 'CSE-302' ||
          auth.activeClassroom?.code == 'CSE302';
      return is302
          ? [
              const CameraModel(
                id: 'CAM003',
                name: 'Classroom 302 Front',
                status: 'online',
              ),
              const CameraModel(
                id: 'CAM004',
                name: 'Classroom 302 Rear',
                status: 'online',
              ),
            ]
          : [
              const CameraModel(
                id: 'CAM001',
                name: 'Classroom 301 Front',
                status: 'online',
              ),
              const CameraModel(
                id: 'CAM002',
                name: 'Classroom 301 Rear',
                status: 'online',
              ),
            ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final teacherProvider = context.watch<TeacherProvider>();
    final cameras = _getCameras(authProvider, adminProvider, teacherProvider);

    if (cameras.isNotEmpty && !cameras.any((c) => c.id == _selectedCameraId)) {
      _selectedCameraId = cameras.first.id;
    }

    final selectedCam = cameras.firstWhere(
      (c) => c.id == _selectedCameraId,
      orElse: () => cameras.isNotEmpty
          ? cameras.first
          : const CameraModel(id: 'CAM001', name: 'Front Camera'),
    );
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: 'Live Camera Stream',
            subtitle: authProvider.activeClassroom != null
                ? 'Session: ${authProvider.activeClassroom!.name}'
                : 'Backend AI Multi-Camera Feeds',
            onRefresh: _loadCameras,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Camera Selector & View Mode Switcher
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: cameras.map((c) {
                              final isSelected = c.id == _selectedCameraId;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCameraId = c.id;
                                      _isGridView = false;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: isSelected
                                        ? ClayStyles.raised(
                                            color: palette.primaryBlue,
                                            radius: 14,
                                            depth: 3,
                                            shadowColor: palette.primaryBlue
                                                .withOpacity(0.4),
                                            isDark: isDark,
                                          )
                                        : ClayStyles.raised(
                                            color: palette.card,
                                            radius: 14,
                                            depth: 2,
                                            isDark: isDark,
                                          ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.videocam_rounded,
                                          size: 16,
                                          color: isSelected
                                              ? Colors.white
                                              : palette.primaryBlue,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          c.id,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : palette.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View Mode Toggle (Single vs Grid)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: palette.canvasDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isGridView = false),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: !_isGridView
                                      ? palette.card
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.crop_square_rounded,
                                  size: 16,
                                  color: !_isGridView
                                      ? palette.primaryBlue
                                      : palette.textMuted,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isGridView = true),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _isGridView
                                      ? palette.card
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.grid_view_rounded,
                                  size: 16,
                                  color: _isGridView
                                      ? palette.primaryBlue
                                      : palette.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Player View (Single or Multi-Grid)
                  if (!_isGridView)
                    CameraPlayer(
                      cameraId: selectedCam.id,
                      cameraName: selectedCam.name,
                      serverUrl: authProvider.serverUrl,
                      token: authProvider.token,
                      isExpanded: true,
                      fps: 1,
                    )
                  else
                    Column(
                      children: cameras.map((c) {
                        return CameraPlayer(
                          cameraId: c.id,
                          cameraName: c.name,
                          serverUrl: authProvider.serverUrl,
                          token: authProvider.token,
                          isExpanded: false,
                          fps: 1,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),

                  // AI Inference Architecture Notice
                  ClayCard(
                    color: ClayColors.clayLavender,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: palette.primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.memory_rounded,
                            size: 20,
                            color: palette.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Backend AI Inference Pipeline',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AI pose estimation and detection run exclusively inside Flask OpenCV workers on your host machine. The mobile client streams processed JPEG frames without running duplicate local models or consuming excessive phone battery.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: palette.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
