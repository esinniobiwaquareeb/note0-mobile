import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/encrypted_file_store.dart';
import '../../data/note.dart';
import '../../data/notes_repository.dart';
import '../../core/utils/extensions.dart';
import '../../core/services/usage_service.dart';
import '../../core/services/auth_service.dart';

final encryptedStoreProvider = Provider<EncryptedFileStore>((ref) {
  return EncryptedFileStore();
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(encryptedStoreProvider));
});

final notesControllerProvider =
    AsyncNotifierProvider<NotesController, List<Note>>(NotesController.new);


final isAnalyzingProvider = StateProvider<bool>((ref) => false);

class NotesController extends AsyncNotifier<List<Note>> {

  final _uuid = const Uuid();
  String get _baseUrl => dotenv.get('API_BASE_URL');
  final Map<String, Note> _pendingNotes = {};

  @override
  Future<List<Note>> build() async {
    // We'll primarily list from the backend now
    return await fetchNotes();
  }

  void _updateState(List<Note> fetchedNotes) {
    final List<Note> merged = [];
    merged.addAll(_pendingNotes.values);
    for (var n in fetchedNotes) {
      if (!_pendingNotes.containsKey(n.id)) {
        merged.add(n);
      }
    }
    state = AsyncData(merged);
  }

  Future<List<Note>> fetchNotes() async {
    List<Note> fetched = [];
    try {
      final guestId = await ref.read(usageServiceProvider).getGuestId();
      final headers = await ref.read(authServiceProvider).getAuthHeaders();
      headers['x-guest-id'] = guestId;
      final response = await http.get(
        Uri.parse('$_baseUrl/notes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        fetched = json.map((m) => Note.fromJson(m)).toList();
      } else {
        fetched = await ref.read(notesRepositoryProvider).list();
      }
    } catch (e) {
      fetched = await ref.read(notesRepositoryProvider).list();
    }

    // Merge with pending notes
    final List<Note> merged = [];
    merged.addAll(_pendingNotes.values);
    for (var n in fetched) {
      if (!_pendingNotes.containsKey(n.id)) {
        merged.add(n);
      }
    }
    return merged;
  }

  // Asynchronous Background Operations
  Future<void> startAudioProcessing(
    String localFilePath, {
    required void Function(Note) onComplete,
    required void Function(String) onError,
  }) async {
    final tempId = 'temp_${_uuid.v4()}';
    final tempNote = Note(
      id: tempId,
      title: 'Transcribing Audio...',
      content: 'Uploading and processing audio transcription & analysis with AI in the background.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isProcessing: true,
      audioPath: localFilePath,
    );

    _pendingNotes[tempId] = tempNote;
    _updateState(state.asData?.value ?? []);

    _uploadAndAnalyzeBackground(tempId, localFilePath, onComplete, onError);
  }

  Future<void> _uploadAndAnalyzeBackground(
    String tempId,
    String localFilePath,
    void Function(Note) onComplete,
    void Function(String) onError,
  ) async {
    try {
      final note = await uploadRecording(localFilePath);
      _pendingNotes.remove(tempId);
      final list = await fetchNotes();
      state = AsyncData(list);
      onComplete(note);
    } catch (e) {
      _pendingNotes.remove(tempId);
      final list = await fetchNotes();
      state = AsyncData(list);
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> startYoutubeProcessing(
    String videoUrl, {
    required void Function(Note) onComplete,
    required void Function(String) onError,
  }) async {
    final tempId = 'temp_${_uuid.v4()}';
    final tempNote = Note(
      id: tempId,
      title: 'Processing YouTube...',
      content: 'Fetching YouTube video, transcribing audio, and analyzing content in the background.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isProcessing: true,
    );

    _pendingNotes[tempId] = tempNote;
    _updateState(state.asData?.value ?? []);

    _youtubeBackground(tempId, videoUrl, onComplete, onError);
  }

  Future<void> _youtubeBackground(
    String tempId,
    String videoUrl,
    void Function(Note) onComplete,
    void Function(String) onError,
  ) async {
    try {
      final note = await uploadYoutube(videoUrl);
      _pendingNotes.remove(tempId);
      final list = await fetchNotes();
      state = AsyncData(list);
      onComplete(note);
    } catch (e) {
      _pendingNotes.remove(tempId);
      final list = await fetchNotes();
      state = AsyncData(list);
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> startScanProcessing(
    String imagePath, {
    required void Function(Note) onComplete,
    required void Function(String) onError,
  }) async {
    final tempId = 'temp_${_uuid.v4()}';
    final tempNote = Note(
      id: tempId,
      title: 'Analyzing Document...',
      content: 'Extracting text via OCR and compiling concepts with AI in the background.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isProcessing: true,
    );

    _pendingNotes[tempId] = tempNote;
    _updateState(state.asData?.value ?? []);

    _scanBackground(tempId, imagePath, onComplete, onError);
  }

  Future<void> _scanBackground(
    String tempId,
    String imagePath,
    void Function(Note) onComplete,
    void Function(String) onError,
  ) async {
    try {
      final note = await uploadScan(imagePath);
      _pendingNotes.remove(tempId);
      final list = await fetchNotes();
      state = AsyncData(list);
      onComplete(note);
    } catch (e) {
      _pendingNotes.remove(tempId);
      final list = await fetchNotes();
      state = AsyncData(list);
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Note> uploadRecording(String filePath) async {
    final guestId = await ref.read(usageServiceProvider).getGuestId();
    final url = Uri.parse('$_baseUrl/notes/upload');
    
    try {
      final authHeaders = await ref.read(authServiceProvider).getAuthHeaders();
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(authHeaders)
        ..headers['x-guest-id'] = guestId
        ..files.add(await http.MultipartFile.fromPath('audio', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final noteJson = jsonDecode(response.body);
        final note = Note.fromJson(noteJson);
        
        await ref.read(notesRepositoryProvider).upsert(note);
        final authService = ref.read(authServiceProvider);
        if (!await authService.isAuthenticated()) {
          await ref.read(usageServiceProvider).incrementRecordingCount();
        }
        return note;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload recording');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Note> uploadScan(String filePath) async {
    final guestId = await ref.read(usageServiceProvider).getGuestId();
    final url = Uri.parse('$_baseUrl/notes/upload-scan');
    
    try {
      final authHeaders = await ref.read(authServiceProvider).getAuthHeaders();
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(authHeaders)
        ..headers['x-guest-id'] = guestId
        ..files.add(await http.MultipartFile.fromPath('image', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final noteJson = jsonDecode(response.body);
        final note = Note.fromJson(noteJson);
        await ref.read(notesRepositoryProvider).upsert(note);
        final authService = ref.read(authServiceProvider);
        if (!await authService.isAuthenticated()) {
          await ref.read(usageServiceProvider).incrementRecordingCount();
        }
        return note;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload scan');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Note> uploadYoutube(String url) async {
    final guestId = await ref.read(usageServiceProvider).getGuestId();
    final requestUrl = Uri.parse('$_baseUrl/notes/youtube');
    
    try {
      final authHeaders = await ref.read(authServiceProvider).getAuthHeaders(json: true);
      final response = await http.post(
        requestUrl,
        headers: {
          ...authHeaders,
          'x-guest-id': guestId,
        },
        body: jsonEncode({'url': url}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final noteJson = jsonDecode(response.body);
        final note = Note.fromJson(noteJson);
        await ref.read(notesRepositoryProvider).upsert(note);
        final authService = ref.read(authServiceProvider);
        if (!await authService.isAuthenticated()) {
          await ref.read(usageServiceProvider).incrementRecordingCount();
        }
        return note;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to analyze YouTube video');
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<Note> createEmpty() async {

    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: '',
      content: '',
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(notesRepositoryProvider).upsert(note);
    state = AsyncData(await ref.read(notesRepositoryProvider).list());
    return note;
  }

  Future<void> upsert({
    required String id,
    required String title,
    required String content,
    String? transcript,
    String? audioPath,
    List<Map<String, dynamic>>? actionItems,
    List<Map<String, dynamic>>? flashcards,
    List<Map<String, dynamic>>? quiz,
    String? blindSpots,
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    final existing = state.asData?.value.firstWhereOrNull(
      (n) => n.id == id,
    );

    final base =
        existing ??
        Note(
          id: id,
          title: '',
          content: '',
          transcript: '',
          audioPath: audioPath,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    final now = DateTime.now();
    final note = base.copyWith(
      title: title, 
      content: content, 
      transcript: transcript,
      audioPath: audioPath ?? base.audioPath,
      actionItems: actionItems ?? base.actionItems,
      flashcards: flashcards ?? base.flashcards,
      quiz: quiz ?? base.quiz,
      blindSpots: blindSpots ?? base.blindSpots,
      chatHistory: chatHistory ?? base.chatHistory,
      updatedAt: now,
    );

    await ref.read(notesRepositoryProvider).upsert(note);
    state = AsyncData(await ref.read(notesRepositoryProvider).list());

    try {
      final guestId = await ref.read(usageServiceProvider).getGuestId();
      final headers = await ref.read(authServiceProvider).getAuthHeaders(json: true);
      headers['x-guest-id'] = guestId;
      final response = await http.patch(
        Uri.parse('$_baseUrl/notes/$id'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'content': content,
          if (transcript != null) 'transcript': transcript,
          if (actionItems != null) 'actionItems': actionItems,
          if (flashcards != null) 'flashcards': flashcards,
        }),
      );
      if (response.statusCode == 200) {
        final noteJson = jsonDecode(response.body);
        final backendNote = Note.fromJson(noteJson);
        await ref.read(notesRepositoryProvider).upsert(backendNote);
        state = AsyncData(await ref.read(notesRepositoryProvider).list());
      }
    } catch (_) {
      // Handle connection error gracefully
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final guestId = await ref.read(usageServiceProvider).getGuestId();
      final headers = await ref.read(authServiceProvider).getAuthHeaders();
      headers['x-guest-id'] = guestId;
      await http.delete(
        Uri.parse('$_baseUrl/notes/$id'),
        headers: headers,
      );
    } catch (_) {}
    await ref.read(notesRepositoryProvider).deleteById(id);
    state = AsyncData(await fetchNotes());
  }

  Future<Note> regenerateQuiz(String noteId) async {
    final guestId = await ref.read(usageServiceProvider).getGuestId();
    final headers = await ref.read(authServiceProvider).getAuthHeaders();
    headers['x-guest-id'] = guestId;
    final response = await http.post(
      Uri.parse('$_baseUrl/notes/$noteId/regenerate-quiz'),
      headers: headers,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final noteJson = jsonDecode(response.body);
      final updatedNote = Note.fromJson(noteJson);
      await ref.read(notesRepositoryProvider).upsert(updatedNote);
      state = AsyncData(await fetchNotes());
      return updatedNote;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to regenerate quiz');
    }
  }

  Future<Note> translateNote(String noteId, String targetLanguage) async {
    final guestId = await ref.read(usageServiceProvider).getGuestId();
    final headers = await ref.read(authServiceProvider).getAuthHeaders(json: true);
    headers['x-guest-id'] = guestId;
    final response = await http.post(
      Uri.parse('$_baseUrl/notes/$noteId/translate'),
      headers: headers,
      body: jsonEncode({'targetLanguage': targetLanguage}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final noteJson = jsonDecode(response.body);
      final updatedNote = Note.fromJson(noteJson);
      await ref.read(notesRepositoryProvider).upsert(updatedNote);
      state = AsyncData(await fetchNotes());
      return updatedNote;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to translate note');
    }
  }

  Future<void> moveToFolder(String noteId, String? folderId) async {
    final notes = state.asData?.value ?? [];
    Note? note = notes.firstWhereOrNull((n) => n.id == noteId);
    
    if (note != null) {
      final updatedNote = note.copyWith(folderId: folderId, updatedAt: DateTime.now());
      await ref.read(notesRepositoryProvider).upsert(updatedNote);
      state = AsyncData(await ref.read(notesRepositoryProvider).list());
      
      try {
        final guestId = await ref.read(usageServiceProvider).getGuestId();
        final headers = await ref.read(authServiceProvider).getAuthHeaders(json: true);
        headers['x-guest-id'] = guestId;
        await http.patch(
          Uri.parse('$_baseUrl/notes/$noteId'),
          headers: headers,
          body: jsonEncode({'folderId': folderId}),
        );
      } catch (_) {}
    }
  }

  Future<void> toggleActionItem(String noteId, int index) async {
    final notes = state.asData?.value ?? [];
    final note = notes.firstWhereOrNull((n) => n.id == noteId);
    if (note == null) return;

    final items = List<Map<String, dynamic>>.from(note.actionItems);
    if (index >= 0 && index < items.length) {
      final item = Map<String, dynamic>.from(items[index]);
      item['isCompleted'] = !(item['isCompleted'] ?? false);
      items[index] = item;
      
      final updatedNote = note.copyWith(actionItems: items, updatedAt: DateTime.now());
      await ref.read(notesRepositoryProvider).upsert(updatedNote);
      state = AsyncData(await ref.read(notesRepositoryProvider).list());

      try {
        final guestId = await ref.read(usageServiceProvider).getGuestId();
        final headers = await ref.read(authServiceProvider).getAuthHeaders(json: true);
        headers['x-guest-id'] = guestId;
        await http.patch(
          Uri.parse('$_baseUrl/notes/$noteId'),
          headers: headers,
          body: jsonEncode({'actionItems': items}),
        );
      } catch (_) {}
    }
  }
}
