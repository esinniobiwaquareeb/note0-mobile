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
  String get _baseUrl => dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000/v1');

  @override
  Future<List<Note>> build() async {
    // We'll primarily list from the backend now
    return await fetchNotes();
  }

  Future<List<Note>> fetchNotes() async {
    try {
      final guestId = await ref.read(usageServiceProvider).getGuestId();
      // In a real app, we'd add Auth token here if logged in
      final response = await http.get(
        Uri.parse('$_baseUrl/notes'),
        headers: {
          'x-guest-id': guestId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((m) => Note.fromJson(m)).toList();
      }
    } catch (e) {
      // Fallback to local if API fails
      return await ref.read(notesRepositoryProvider).list();
    }
    return await ref.read(notesRepositoryProvider).list();
  }

  Future<Note> uploadRecording(String filePath) async {
    final guestId = await ref.read(usageServiceProvider).getGuestId();
    final url = Uri.parse('$_baseUrl/notes/upload');
    
    // Set analyzing state
    ref.read(isAnalyzingProvider.notifier).state = true;
    
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers['x-guest-id'] = guestId
        ..files.add(await http.MultipartFile.fromPath('audio', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final noteJson = jsonDecode(response.body);
        final note = Note.fromJson(noteJson);
        
        // Save locally as well for offline
        await ref.read(notesRepositoryProvider).upsert(note);
        
        // Refresh state
        state = AsyncData(await fetchNotes());
        return note;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload recording');
      }
    } finally {
      ref.read(isAnalyzingProvider.notifier).state = false;
    }
  }

  Future<Note> uploadScan(String filePath) async {
    final guestId = await ref.read(usageServiceProvider).getGuestId();
    final url = Uri.parse('$_baseUrl/notes/upload-scan');
    
    ref.read(isAnalyzingProvider.notifier).state = true;
    
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers['x-guest-id'] = guestId
        ..files.add(await http.MultipartFile.fromPath('image', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final noteJson = jsonDecode(response.body);
        final note = Note.fromJson(noteJson);
        await ref.read(notesRepositoryProvider).upsert(note);
        state = AsyncData(await fetchNotes());
        return note;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload scan');
      }
    } finally {
      ref.read(isAnalyzingProvider.notifier).state = false;
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
      updatedAt: now,
    );

    await ref.read(notesRepositoryProvider).upsert(note);
    state = AsyncData(await ref.read(notesRepositoryProvider).list());
  }

  Future<void> deleteNote(String id) async {
    await ref.read(notesRepositoryProvider).deleteById(id);
    state = AsyncData(await ref.read(notesRepositoryProvider).list());
  }

  Future<void> moveToFolder(String noteId, String? folderId) async {
    final notes = state.asData?.value ?? [];
    Note? note = notes.firstWhereOrNull((n) => n.id == noteId);
    
    if (note != null) {

      final updatedNote = note.copyWith(folderId: folderId, updatedAt: DateTime.now());
      await ref.read(notesRepositoryProvider).upsert(updatedNote);
      state = AsyncData(await ref.read(notesRepositoryProvider).list());
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
    }
  }
}
