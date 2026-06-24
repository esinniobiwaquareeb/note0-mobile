import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:gap/gap.dart';

class FlashcardsStudyScreen extends StatefulWidget {
  const FlashcardsStudyScreen({super.key, required this.flashcards});
  final List<Map<String, dynamic>> flashcards;

  @override
  State<FlashcardsStudyScreen> createState() => _FlashcardsStudyScreenState();
}

class _FlashcardsStudyScreenState extends State<FlashcardsStudyScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  late PageController _pageController;

  // Active recall stats
  int _rememberedCount = 0;
  int _forgotCount = 0;
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _gradeCard(bool remembered) {
    if (remembered) {
      _rememberedCount++;
    } else {
      _forgotCount++;
    }

    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _isFlipped = false;
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() {
        _showSummary = true;
      });
    }
  }

  void _resetSession() {
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _rememberedCount = 0;
      _forgotCount = 0;
      _showSummary = false;
    });
    _pageController.jumpToPage(0);
  }

  String _getEncouragingMessage(double accuracy) {
    if (accuracy >= 1.0) return 'Perfect score! You have mastered these terms! 🚀';
    if (accuracy >= 0.8) return 'Great job! You have strong retention of these concepts. ✨';
    if (accuracy >= 0.5) return 'Good start! Review a few more times to lock them in. 📚';
    return 'Keep practicing! Reviewing regularly strengthens long-term memory. 💪';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.flashcards.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(title: const Text('Study Mode')),
        body: const Center(child: Text('No flashcards available.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Spaced Recall Study'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _showSummary ? _buildSummaryView(isDark) : _buildStudyView(isDark),
    );
  }

  Widget _buildSummaryView(bool isDark) {
    final total = widget.flashcards.length;
    final accuracy = total > 0 ? _rememberedCount / total : 0.0;
    final percent = (accuracy * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.amber,
                  size: 80,
                ),
                const Gap(16),
                const Text(
                  'Session Completed!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Gap(24),
                // Progress gauge text
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: accuracy >= 0.8
                        ? Colors.green
                        : (accuracy >= 0.5 ? Colors.orange : Colors.red),
                  ),
                ),
                const Text(
                  'Accuracy Score',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const Gap(32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol(
                      label: 'REMEMBERED',
                      val: '$_rememberedCount',
                      color: Colors.green,
                    ),
                    Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2)),
                    _buildStatCol(
                      label: 'FORGOT',
                      val: '$_forgotCount',
                      color: Colors.red,
                    ),
                  ],
                ),
                const Gap(32),
                Text(
                  _getEncouragingMessage(accuracy),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Gap(40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetSession,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: Colors.blue, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Study Again',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol({required String label, required String val, required Color color}) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        const Gap(4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildStudyView(bool isDark) {
    final card = widget.flashcards[_currentIndex];

    return Column(
      children: [
        const Gap(40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.flashcards.length,
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
            backgroundColor: Colors.blue.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(Colors.blue),
          ),
        ),
        const Gap(12),
        Text(
          'Card ${_currentIndex + 1} of ${widget.flashcards.length}',
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const Gap(30),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.flashcards.length,
            itemBuilder: (context, index) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GestureDetector(
                    onTap: () => setState(() => _isFlipped = !_isFlipped),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 400,
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: _isFlipped 
                              ? Colors.green.withOpacity(0.5) 
                              : Colors.blue.withOpacity(0.5), 
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isFlipped 
                                ? Colors.green.withOpacity(0.08) 
                                : Colors.blue.withOpacity(0.08),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isFlipped ? Icons.check_circle_outline : Icons.help_outline,
                            color: _isFlipped ? Colors.green : Colors.blue,
                            size: 40,
                          ),
                          const Gap(20),
                          Text(
                            _isFlipped ? 'DEFINITION' : 'TERM',
                            style: TextStyle(
                              fontSize: 11, 
                              fontWeight: FontWeight.w900, 
                              color: _isFlipped 
                                  ? Colors.green.withOpacity(0.7) 
                                  : Colors.blue.withOpacity(0.7),
                              letterSpacing: 3,
                            ),
                          ),
                          const Gap(24),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Text(
                                  _isFlipped ? (card['back'] ?? '') : (card['front'] ?? ''),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22, 
                                    fontWeight: FontWeight.bold, 
                                    color: isDark ? Colors.white : Colors.black,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Gap(24),
                          Text(
                            _isFlipped ? 'Tap to see term' : 'Tap to reveal definition',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isFlipped
                ? Row(
                    key: const ValueKey('recall_grading_buttons'),
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _gradeCard(false),
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text('Forgot'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _gradeCard(true),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Remembered'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    key: const ValueKey('reveal_answer_button'),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isFlipped = true),
                      icon: const Icon(Icons.visibility, color: Colors.white),
                      label: const Text('Show Answer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
          ),
        ),
        const Gap(20),
      ],
    );
  }
}
