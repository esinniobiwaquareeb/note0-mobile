import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

final recordingControllerProvider = StateNotifierProvider<RecordingController, RecordingState>((ref) {
  return RecordingController();
});

class RecordingState {
  final bool isRecording;
  final Duration duration;
  final String? path;
  final double amplitude;

  RecordingState({
    this.isRecording = false,
    this.duration = Duration.zero,
    this.path,
    this.amplitude = -160.0, // Minimum amplitude for record package
  });

  RecordingState copyWith({
    bool? isRecording,
    Duration? duration,
    String? path,
    double? amplitude,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      duration: duration ?? this.duration,
      path: path ?? this.path,
      amplitude: amplitude ?? this.amplitude,
    );
  }
}

class RecordingController extends StateNotifier<RecordingState> {
  RecordingController() : super(RecordingState());

  final _record = AudioRecorder();
  final _uuid = const Uuid();
  Timer? _timer;
  Timer? _amplitudeTimer;

  Future<void> start() async {
    final hasPermission = await _record.hasPermission();
    if (!hasPermission) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${_uuid.v4()}.m4a';

    await _record.start(const RecordConfig(), path: path);
    state = state.copyWith(isRecording: true, path: path, duration: Duration.zero);
    
    _startTimers();
  }

  void _startTimers() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(duration: Duration(seconds: timer.tick));
    });

    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final amplitude = await _record.getAmplitude();
        state = state.copyWith(amplitude: amplitude.current);
      } catch (e) {
        // Silently fail amplitude updates
      }
    });
  }

  void _stopTimers() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _timer = null;
    _amplitudeTimer = null;
  }

  Future<String?> stop() async {
    _stopTimers();
    final path = await _record.stop();
    state = state.copyWith(isRecording: false);
    return path;
  }

  @override
  void dispose() {
    _stopTimers();
    _record.dispose();
    super.dispose();
  }
}
