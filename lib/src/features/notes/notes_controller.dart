import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/encrypted_file_store.dart';
import '../../data/note.dart';
import '../../data/notes_repository.dart';
import '../../core/utils/extensions.dart';


final encryptedStoreProvider = Provider<EncryptedFileStore>((ref) {
  return EncryptedFileStore();
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(encryptedStoreProvider));
});

final notesControllerProvider =
    AsyncNotifierProvider<NotesController, List<Note>>(NotesController.new);

class NotesController extends AsyncNotifier<List<Note>> {
  final _uuid = const Uuid();

  @override
  Future<List<Note>> build() async {
    final notes = await ref.read(notesRepositoryProvider).list();
    return notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
