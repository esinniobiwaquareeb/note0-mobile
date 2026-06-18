import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'recording_controller.dart';
import '../../core/theme/app_theme.dart';

class AudioRecordingScreen extends ConsumerStatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  ConsumerState<AudioRecordingScreen> createState() =>
      _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends ConsumerState<AudioRecordingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recordingControllerProvider.notifier).start();
    });
  }

  Future<void> _stopRecording() async {
    final path = await ref.read(recordingControllerProvider.notifier).stop();
    if (mounted) {
      Navigator.pop(context, path);
    }
  }

  String _formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Single source of truth: controller state (no local timer needed)
    final recordingState = ref.watch(recordingControllerProvider);
    final isRecording = recordingState.isRecording;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recording'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.red, size: 48),
            )
                .animate(onPlay: (c) => isRecording ? c.repeat() : null)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 1.seconds,
                  curve: Curves.easeInOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.2, 1.2),
                  end: const Offset(1, 1),
                  duration: 1.seconds,
                  curve: Curves.easeInOut,
                ),
          ),
          const Gap(40),
          Text(
            _formatDuration(recordingState.duration),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          const Text(
            'Recording in progress...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Cancel',
                  onTap: () => Navigator.pop(context),
                  color: Colors.grey,
                ),
                _ActionButton(
                  icon: Icons.stop,
                  label: 'Finish',
                  onTap: _stopRecording,
                  color: Colors.red,
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isPrimary ? color : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isPrimary ? Colors.white : color),
          ),
          const Gap(8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
