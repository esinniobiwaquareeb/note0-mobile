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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _next() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _isFlipped = false;
        _currentIndex++;
      });
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() {
        _isFlipped = false;
        _currentIndex--;
      });
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = widget.flashcards[_currentIndex];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Study Mode'),
        centerTitle: true,
      ),
      body: Column(
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
          const Gap(40),
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
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        height: 400,
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isFlipped ? Icons.lightbulb : Icons.help_outline,
                              color: Colors.blue,
                              size: 40,
                            ),
                            const Gap(24),
                            Text(
                              _isFlipped ? 'DEFINITION' : 'TERM',
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.w900, 
                                color: Colors.blue.withOpacity(0.6),
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
                                      fontSize: 24, 
                                      fontWeight: FontWeight.bold, 
                                      color: isDark ? Colors.white : Colors.black,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Gap(24),
                            const Text(
                              'Tap to reveal',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prev,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(_currentIndex == widget.flashcards.length - 1 ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
          const Gap(20),
        ],
      ),
    );
  }
}
