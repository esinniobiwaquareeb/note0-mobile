import 'note.dart';
import 'folder.dart';
import 'encrypted_file_store.dart';

class NotesRepository {
  NotesRepository(this._store);

  final EncryptedFileStore _store;

  Future<List<Note>> list() async {
    final json = await _store.readJson();
    final items = (json?['notes'] as List<Object?>?) ?? const [];
    return items
        .cast<Map<Object?, Object?>>()
        .map((m) => Note.fromJson(m.cast<String, Object?>()))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> upsert(Note note) async {
    final data = (await _store.readJson()) ?? {};
    final notesJson = (data['notes'] as List<Object?>?) ?? [];
    final notes = notesJson
        .cast<Map<Object?, Object?>>()
        .map((m) => Note.fromJson(m.cast<String, Object?>()))
        .toList();

    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      notes[idx] = note;
    } else {
      notes.add(note);
    }

    data['notes'] = notes.map((n) => n.toJson()).toList();
    await _store.writeJson(data);
  }

  Future<void> deleteById(String id) async {
    final data = (await _store.readJson()) ?? {};
    final notesJson = (data['notes'] as List<Object?>?) ?? [];
    final notes = notesJson
        .cast<Map<Object?, Object?>>()
        .map((m) => Note.fromJson(m.cast<String, Object?>()))
        .toList();

    notes.removeWhere((n) => n.id == id);
    data['notes'] = notes.map((n) => n.toJson()).toList();
    await _store.writeJson(data);
  }

  // --- Folder Management ---

  Future<List<Folder>> listFolders() async {
    final json = await _store.readJson();
    final items = (json?['folders'] as List<Object?>?) ?? const [];
    return items
        .cast<Map<Object?, Object?>>()
        .map((m) => Folder.fromJson(m.cast<String, Object?>()))
        .toList();
  }

  Future<void> upsertFolder(Folder folder) async {
    final data = (await _store.readJson()) ?? {};
    final foldersJson = (data['folders'] as List<Object?>?) ?? [];
    final folders = foldersJson
        .cast<Map<Object?, Object?>>()
        .map((m) => Folder.fromJson(m.cast<String, Object?>()))
        .toList();

    final idx = folders.indexWhere((f) => f.id == folder.id);
    if (idx >= 0) {
      folders[idx] = folder;
    } else {
      folders.add(folder);
    }

    data['folders'] = folders.map((f) => f.toJson()).toList();
    await _store.writeJson(data);
  }

  Future<void> deleteFolderById(String id) async {
    final data = (await _store.readJson()) ?? {};
    final foldersJson = (data['folders'] as List<Object?>?) ?? [];
    final folders = foldersJson
        .cast<Map<Object?, Object?>>()
        .map((m) => Folder.fromJson(m.cast<String, Object?>()))
        .toList();

    folders.removeWhere((f) => f.id == id);
    data['folders'] = folders.map((f) => f.toJson()).toList();

    // Also remove folder reference from notes
    final notesJson = (data['notes'] as List<Object?>?) ?? [];
    final notes = notesJson
        .cast<Map<Object?, Object?>>()
        .map((m) => Note.fromJson(m.cast<String, Object?>()))
        .toList();

    final updatedNotes = notes.map((n) {
      if (n.folderId == id) return n.copyWith(folderId: null);
      return n;
    }).toList();

    data['notes'] = updatedNotes.map((n) => n.toJson()).toList();
    await _store.writeJson(data);
  }
}

