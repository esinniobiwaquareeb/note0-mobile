import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.title, required this.questions});

  final String title;
  final List<Map<String, dynamic>> questions;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  int _score = 0;
  bool _isFinished = false;

  void _handleAnswer(int index) {
    if (_selectedAnswer != null) return;
    
    setState(() {
      _selectedAnswer = index;
      if (index == widget.questions[_currentIndex]['correctIndex']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      setState(() => _isFinished = true);
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
          'Quiz: ${widget.title}',
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isFinished ? _buildResult() : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    final Map<String, dynamic> question = widget.questions[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = List<String>.from(question['options'] ?? []);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          const Gap(32),
          Text(
            'QUESTION ${_currentIndex + 1} OF ${widget.questions.length}',
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const Gap(12),
          Text(
            question['question'] ?? '',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
          ),
          const Gap(32),
          ...List.generate(options.length, (index) {
            final isSelected = _selectedAnswer == index;
            final isCorrect = index == question['correctIndex'];
            
            Color bgColor = isDark ? AppTheme.darkSurface : Colors.white;
            Color borderColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);

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
                            color: isDark ? Colors.white : Colors.black
                          ),
                        ),
                      ),
                      if (_selectedAnswer != null) 
                        Icon(
                          isCorrect ? Icons.check_circle : (isSelected ? Icons.cancel : null),
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (_selectedAnswer != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _currentIndex == widget.questions.length - 1 ? 'Finish Quiz' : 'Next Question',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = (_score / widget.questions.length) * 100;

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
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ),
            const Gap(32),
            Text(
              'Quiz Completed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            const Gap(12),
            Text(
              'You scored $_score out of ${widget.questions.length}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Gap(48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Back to Note',
                  style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
