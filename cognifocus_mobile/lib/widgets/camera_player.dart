import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';
import 'clay_status_badge.dart';

/// Live Camera Player Widget
///
/// Fetches processed frames from the Flask backend OpenCV worker via
/// `/api/cameras/<id>/frame.jpg` with token authentication and smooth byte rendering.
class CameraPlayer extends StatefulWidget {
  final String cameraId;
  final String? cameraName;
  final String serverUrl;
  final String? token;
  final bool isExpanded;
  final int fps;

  const CameraPlayer({
    super.key,
    required this.cameraId,
    this.cameraName,
    required this.serverUrl,
    this.token,
    this.isExpanded = false,
    this.fps = 1,
  });

  @override
  State<CameraPlayer> createState() => _CameraPlayerState();
}

class _CameraPlayerState extends State<CameraPlayer> {
  Timer? _refreshTimer;
  Uint8List? _currentFrameBytes;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isStreaming = true;
  final http.Client _client = http.Client();

  @override
  void initState() {
    super.initState();
    _startFramePolling();
  }

  @override
  void didUpdateWidget(covariant CameraPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraId != widget.cameraId ||
        oldWidget.serverUrl != widget.serverUrl ||
        oldWidget.token != widget.token) {
      _startFramePolling();
    }
  }

  void _startFramePolling() {
    _refreshTimer?.cancel();
    _fetchFrame();

    final intervalMs = (1000 / widget.fps).clamp(800, 3000).toInt();
    _refreshTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_isStreaming && mounted) {
        _fetchFrame();
      }
    });
  }

  Future<void> _fetchFrame() async {
    final frameUrl = ApiConfig.getCameraFrameUrl(
      baseUrl: widget.serverUrl,
      cameraId: widget.cameraId,
      token: widget.token,
    );

    try {
      final headers = <String, String>{};
      if (widget.token != null && widget.token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${widget.token}';
      }

      final response = await _client
          .get(Uri.parse(frameUrl), headers: headers)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentFrameBytes = response.bodyBytes;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted && _currentFrameBytes == null) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted && _currentFrameBytes == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _toggleStreaming() {
    setState(() {
      _isStreaming = !_isStreaming;
    });
    if (_isStreaming) {
      _fetchFrame();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.cameraName ?? 'Camera ${widget.cameraId}';
    final height = widget.isExpanded ? 340.0 : 220.0;
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: ClayStyles.raised(
        color: palette.card,
        radius: 20,
        depth: 6,
        isDark: isDark,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: palette.clayLavender,
              border: Border(
                bottom: BorderSide(color: palette.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        size: 20,
                        color: palette.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${widget.cameraId} • $displayName',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (!_hasError && _isStreaming)
                      ClayStatusBadge.live()
                    else
                      ClayStatusBadge.offline(),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleStreaming,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: palette.card,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: palette.shadowDark.withOpacity(isDark ? 0.3 : 0.1),
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isStreaming
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          size: 20,
                          color: _isStreaming
                              ? palette.primaryBlue
                              : palette.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Video Feed Frame Container
          SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Rendered Frame or Fallback Canvas
                Container(
                  color: const Color(0xFF0F172A), // Dark slate viewport canvas
                  child: _currentFrameBytes != null
                      ? Image.memory(
                          _currentFrameBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        )
                      : null,
                ),

                // Loading Overlay
                if (_isLoading)
                  Container(
                    color: const Color(0xCC0F172A),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ClayColors.primaryBlueLight,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Connecting to camera worker...',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Error Overlay
                if (_hasError && _currentFrameBytes == null)
                  Container(
                    color: const Color(0xEE0F172A),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam_off_rounded,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Camera Feed Unavailable',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Camera ${widget.cameraId} is offline or requires classroom session.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _fetchFrame,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(
                              'Retry Stream',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Footer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: palette.card,
              border: Border(
                top: BorderSide(color: palette.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 13,
                      color: palette.primaryBlue,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AI Inference Active • YOLOv8 Pose',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Backend Stream',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: ClayColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
