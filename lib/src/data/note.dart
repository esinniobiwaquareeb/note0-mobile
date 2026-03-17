// Note model definition

class Note {
  final String id;
  final String title;
  final String content;
  final String summary;
  final List<Map<String, dynamic>> keyConcepts;
  final List<Map<String, dynamic>> commonQuestions;
  final List<String> finalThoughts;
  final List<Map<String, dynamic>> actionItems;
  final List<Map<String, dynamic>> flashcards;
  final String? folderId;
  final String transcript;
  final String? audioPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.summary = '',
    this.keyConcepts = const [],
    this.commonQuestions = const [],
    this.finalThoughts = const [],
    this.actionItems = const [],
    this.flashcards = const [],
    this.folderId,
    this.transcript = '',
    this.audioPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    List<Map<String, dynamic>>? keyConcepts,
    List<Map<String, dynamic>>? commonQuestions,
    List<String>? finalThoughts,
    List<Map<String, dynamic>>? actionItems,
    List<Map<String, dynamic>>? flashcards,
    String? folderId,
    String? transcript,
    String? audioPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      keyConcepts: keyConcepts ?? this.keyConcepts,
      commonQuestions: commonQuestions ?? this.commonQuestions,
      finalThoughts: finalThoughts ?? this.finalThoughts,
      actionItems: actionItems ?? this.actionItems,
      flashcards: flashcards ?? this.flashcards,
      folderId: folderId ?? this.folderId,
      transcript: transcript ?? this.transcript,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'keyConcepts': keyConcepts,
      'commonQuestions': commonQuestions,
      'finalThoughts': finalThoughts,
      'actionItems': actionItems,
      'flashcards': flashcards,
      'folderId': folderId,
      'transcript': transcript,
      'audioPath': audioPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      summary: json['summary'] ?? '',
      keyConcepts: List<Map<String, dynamic>>.from(json['keyConcepts'] ?? []),
      commonQuestions: List<Map<String, dynamic>>.from(json['commonQuestions'] ?? []),
      finalThoughts: List<String>.from(json['finalThoughts'] ?? []),
      actionItems: List<Map<String, dynamic>>.from(json['actionItems'] ?? []),
      flashcards: List<Map<String, dynamic>>.from(json['flashcards'] ?? []),
      folderId: json['folderId'],
      transcript: json['transcript'] ?? '',
      audioPath: json['audioPath'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
