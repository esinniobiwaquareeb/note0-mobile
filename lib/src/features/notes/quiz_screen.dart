import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/toast_utils.dart';
import '../../data/note.dart';
import 'notes_controller.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.note});

  final Note note;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late Note _note;
  int _currentIndex = 0;
  int? _selectedAnswer;
  int _score = 0;
  bool _isFinished = false;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  void _handleAnswer(int index) {
    if (_selectedAnswer != null) return;

    final questions = _note.quiz.isNotEmpty ? _note.quiz : _note.commonQuestions;
    if (questions.isEmpty || _currentIndex >= questions.length) return;

    final correctIndex = questions[_currentIndex]['correctIndex'] ?? 0;
    
    setState(() {
      _selectedAnswer = index;
      if (index == correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    final questions = _note.quiz.isNotEmpty ? _note.quiz : _note.commonQuestions;
    if (_currentIndex < questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      setState(() => _isFinished = true);
    }
  }

  void _retakeQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedAnswer = null;
      _score = 0;
      _isFinished = false;
    });
  }

  Future<void> _regenerateQuiz() async {
    setState(() => _isRegenerating = true);
    try {
      final updatedNote = await ref
          .read(notesControllerProvider.notifier)
          .regenerateQuiz(_note.id);
      if (mounted) {
        setState(() {
          _note = updatedNote;
          _currentIndex = 0;
          _selectedAnswer = null;
          _score = 0;
          _isFinished = false;
        });
        ToastUtils.showSuccess(context, 'Quiz regenerated successfully!');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Failed to regenerate quiz: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quiz: ${_note.title.isEmpty ? 'Note Quiz' : _note.title}',
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isFinished && !_isRegenerating)
            IconButton(
              icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black),
              onPressed: _regenerateQuiz,
              tooltip: 'Regenerate Quiz',
            ),
        ],
      ),
      body: _isRegenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.blue)),
                  Gap(16),
                  Text('Regenerating quiz with AI...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : (_isFinished ? _buildResult() : _buildQuiz()),
    );
  }

  Widget _buildQuiz() {
    final questions = _note.quiz.isNotEmpty ? _note.quiz : _note.commonQuestions;
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No quiz questions found.', style: TextStyle(color: Colors.grey)),
            const Gap(16),
            ElevatedButton(
              onPressed: _regenerateQuiz,
              child: const Text('Generate Quiz'),
            ),
          ],
        ),
      );
    }

    final Map<String, dynamic> question = questions[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Parse options: on older structures we might only have commonQuestions.
    // If options are missing, we default to showing True/False or mock options.
    final rawOptions = question['options'];
    final List<String> options = rawOptions != null 
        ? List<String>.from(rawOptions)
        : ['True', 'False']; // default fallback for binary commonQuestions

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / questions.length,
            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          const Gap(32),
          Text(
            'QUESTION ${_currentIndex + 1} OF ${questions.length}',
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
          const Gap(12),
          Text(
            question['question'] ?? '',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black),
          ),
          const Gap(32),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedAnswer == index;
                final correctIndex = question['correctIndex'] ?? 0;
                final isCorrect = index == correctIndex;

                Color bgColor = isDark ? AppTheme.darkSurface : Colors.white;
                Color borderColor =
                    isDark ? Colors.white10 : Colors.black.withOpacity(0.05);

                if (_selectedAnswer != null) {
                  if (isCorrect) {
                    bgColor = Colors.green.withOpacity(0.1);
                    borderColor = Colors.green;
                  } else if (isSelected) {
                    bgColor = Colors.red.withOpacity(0.1);
                    borderColor = Colors.red;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () => _handleAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              options[index],
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black),
                            ),
                          ),
                          if (_selectedAnswer != null)
                            Icon(
                              isCorrect
                                  ? Icons.check_circle
                                  : (isSelected ? Icons.cancel : null),
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedAnswer != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _currentIndex == questions.length - 1
                      ? 'Finish Quiz'
                      : 'Next Question',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final questions = _note.quiz.isNotEmpty ? _note.quiz : _note.commonQuestions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = questions.isNotEmpty ? (_score / questions.length) * 100 : 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${percentage.toInt()}%',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ),
            ),
            const Gap(32),
            Text(
              'Quiz Completed!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black),
            ),
            const Gap(12),
            Text(
              'You scored $_score out of ${questions.length}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Gap(48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retakeQuiz,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Retake',
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _regenerateQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Regenerate',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Back to Note',
                  style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
