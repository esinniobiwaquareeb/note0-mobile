import '../data/note.dart';

class MockNotes {
  static List<Note> get list => [
    Note(
      id: 'mock-1',
      title: 'Background Noise Analysis',
      content: 'The audio recording contains a mix of human speech and persistent low-frequency hum, likely from an air conditioning unit or server rack nearby...',
      summary: 'This analysis identifies several types of environmental noise present in the recording and provides recommendations for filtration and clarity improvement.',
      keyConcepts: [
        {'title': 'Broadband Noise:', 'description': 'The steady hum at 60Hz detected throughout.'},
        {'title': 'Impulse Noise:', 'description': 'Occasional sharp peaks corresponding to keyboard clicks.'},
      ],
      commonQuestions: [
        {'question': 'Is the speech intelligible?', 'explanation': 'Yes, but requires 6dB gain in the 2-4kHz range.'},
        {'question': 'Can the hum be removed?', 'explanation': 'A high-pass filter above 100Hz will eliminate most of it.'},
      ],
      actionItems: [
        {'task': 'Apply high-pass filter (100Hz)', 'isCompleted': false, 'owner': 'Engineer'},
        {'task': 'Boost 2-4kHz frequency band', 'isCompleted': true, 'owner': 'Engineer'},
        {'task': 'Verify speech intelligibility after processing', 'isCompleted': false, 'owner': 'Auditor'},
      ],
      flashcards: [
        {'front': 'Broadband Noise', 'back': 'Noise that has a constant intensity across a wide range of frequencies.'},
        {'front': 'Impulse Noise', 'back': 'Short, sudden bursts of sound like clicks or pops.'},
      ],
      finalThoughts: [
        'The recording is usable for transcription after minor processing.',
        'Future recordings should use a directional microphone to minimize pickup.',
      ],
      transcript: 'Welcome back to the audio analysis workshop. Today we are looking at background noise. [Silence] As you can hear, there is a low-frequency hum. This is characteristic of electrical interference or server cooling. We need to identify if this broadband noise significantly impacts human speech intelligibility.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    Note(
      id: 'mock-2',
      title: 'Armed Forces Capability',
      content: 'Discussion regarding the physical and mental training required for modern military applications...',
      summary: 'Explores perceptions of military strength and the role of specialized training in building resilience.',
      keyConcepts: [
        {'title': 'Tactical Proficiency:', 'description': 'Technical skills and operational excellence.'},
        {'title': 'Mental Resilience:', 'description': 'The psychological aspect of military performance.'},
      ],
      commonQuestions: [
        {'question': 'Is training standardized?', 'explanation': 'Yes, but specialized units undergo rigorous unique training.'},
      ],
      actionItems: [
        {'task': 'Review specialized unit training protocols', 'isCompleted': false, 'owner': 'Commander'},
        {'task': 'Draft resilience assessment report', 'isCompleted': false, 'owner': 'Psychologist'},
      ],
      flashcards: [
        {'front': 'Tactical Proficiency', 'back': 'Ability to apply technical skills in operationally excellent ways.'},
        {'front': 'Resilience', 'back': 'The capacity to recover quickly from difficulties.'},
      ],
      finalThoughts: [
        'Capability is a mixture of raw strength and refined strategy.',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Note(
      id: 'mock-3',
      title: 'Product Strategy Sync',
      content: 'Meeting notes from the Q3 roadmap planning session. Key focuses include mobile-first development.',
      summary: 'A summary of the upcoming product priorities focusing on AI integration and UX refinement.',
      keyConcepts: [
        {'title': 'AI First:', 'description': 'Prioritizing intelligent features across the core workflow.'},
      ],
      commonQuestions: [
        {'question': 'When is the beta launch?', 'explanation': 'Targeting late August for initial closed testing.'},
      ],
      actionItems: [
        {'task': 'Finalize Q3 Roadmap', 'isCompleted': true, 'owner': 'Product Manager'},
        {'task': 'Start mobile-first UI mocks', 'isCompleted': false, 'owner': 'Designer'},
        {'task': 'Define AI feature set for Beta', 'isCompleted': false, 'owner': 'CTO'},
      ],
      flashcards: [
        {'front': 'Q3 Focus', 'back': 'Mobile-first development and AI integration.'},
      ],
      finalThoughts: [
        'Moving quickly while maintaining high design standards is crucial.',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
