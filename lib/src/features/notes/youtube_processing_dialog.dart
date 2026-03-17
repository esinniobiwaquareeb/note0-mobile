import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../core/theme/app_theme.dart';

class YouTubeProcessingDialog extends StatefulWidget {
  const YouTubeProcessingDialog({super.key});

  @override
  State<YouTubeProcessingDialog> createState() => _YouTubeProcessingDialogState();
}

class _YouTubeProcessingDialogState extends State<YouTubeProcessingDialog> {
  final _controller = TextEditingController();
  final _yt = YoutubeExplode();
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _yt.close();
    super.dispose();
  }

  Future<void> _processUrl() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Basic validation
      final video = await _yt.videos.get(url);
      if (mounted) {
        Navigator.pop(context, video.id.value);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = 'Invalid YouTube URL or video not found.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_circle_outline, color: Colors.red),
                ),
                const Gap(16),
                const Text(
                  'YouTube Video',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(16),
            const Text(
              'Paste a YouTube link to analyze its content and generate structured notes.',
              style: TextStyle(color: Colors.grey),
            ),
            const Gap(24),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_isProcessing,
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=...',
                errorText: _error,
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _processUrl(),
            ),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Gap(8),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    minimumSize: const Size(100, 48),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Analyze'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
