import 'dart:convert';

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
  final List<Map<String, dynamic>> quiz;
  final String? blindSpots;
  final List<Map<String, dynamic>> chatHistory;
  final String? folderId;
  final String transcript;
  // audioPath holds either a full local device path (right after recording)
  // or just the filename (e.g. "abc123.m4a") as returned by the backend.
  final String? audioPath;
  final String? audioUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isProcessing;

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
    this.quiz = const [],
    this.blindSpots,
    this.chatHistory = const [],
    this.folderId,
    this.transcript = '',
    this.audioPath,
    this.audioUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isProcessing = false,
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
    List<Map<String, dynamic>>? quiz,
    String? blindSpots,
    List<Map<String, dynamic>>? chatHistory,
    String? folderId,
    String? transcript,
    String? audioPath,
    String? audioUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isProcessing,
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
      quiz: quiz ?? this.quiz,
      blindSpots: blindSpots ?? this.blindSpots,
      chatHistory: chatHistory ?? this.chatHistory,
      folderId: folderId ?? this.folderId,
      transcript: transcript ?? this.transcript,
      audioPath: audioPath ?? this.audioPath,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isProcessing: isProcessing ?? this.isProcessing,
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
      'quiz': quiz,
      'blindSpots': blindSpots,
      'chatHistory': chatHistory,
      'folderId': folderId,
      'transcript': transcript,
      'audioPath': audioPath,
      'audioUrl': audioUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isProcessing': isProcessing,
    };
  }

  static List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      if (data.trim().isEmpty) return [];
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(
              decoded.map((e) => Map<String, dynamic>.from(e)));
        }
      } catch (_) {
        return [];
      }
    }
    if (data is List) {
      return List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e)));
    }
    return [];
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      if (data.trim().isEmpty) return [];
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return List<String>.from(decoded.map((e) => e.toString()));
        }
      } catch (_) {
        return [];
      }
    }
    if (data is List) {
      return List<String>.from(data.map((e) => e.toString()));
    }
    return [];
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      summary: json['summary'] ?? '',
      keyConcepts: _parseList(json['keyConcepts']),
      commonQuestions: _parseList(json['commonQuestions']),
      finalThoughts: _parseStringList(json['finalThoughts']),
      actionItems: _parseList(json['actionItems']),
      flashcards: _parseList(json['flashcards']),
      quiz: _parseList(json['quiz']),
      blindSpots: json['blindSpots'],
      chatHistory: _parseList(json['chatHistory']),
      folderId: json['folderId'],
      transcript: json['transcript'] ?? '',
      // Backend returns 'audioUrl' (filename only); local recordings use 'audioPath' (full path).
      audioPath: json['audioPath'],
      audioUrl: json['audioUrl'] ?? json['audio_url'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isProcessing: json['isProcessing'] ?? false,
    );
  }
}
