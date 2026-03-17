import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/folder.dart';
import 'notes_controller.dart';

final foldersControllerProvider =
    AsyncNotifierProvider<FoldersController, List<Folder>>(FoldersController.new);

class FoldersController extends AsyncNotifier<List<Folder>> {
  final _uuid = const Uuid();

  @override
  Future<List<Folder>> build() async {
    return ref.read(notesRepositoryProvider).listFolders();
  }

  Future<void> createFolder(String name, int iconCode, int colorValue) async {
    final folder = Folder(
      id: _uuid.v4(),
      name: name,
      iconCode: iconCode,
      colorValue: colorValue,
    );
    await ref.read(notesRepositoryProvider).upsertFolder(folder);
    state = AsyncData(await ref.read(notesRepositoryProvider).listFolders());
  }

  Future<void> updateFolder(Folder folder) async {
    await ref.read(notesRepositoryProvider).upsertFolder(folder);
    state = AsyncData(await ref.read(notesRepositoryProvider).listFolders());
  }

  Future<void> deleteFolder(String id) async {
    await ref.read(notesRepositoryProvider).deleteFolderById(id);
    state = AsyncData(await ref.read(notesRepositoryProvider).listFolders());
    // Refresh notes as they might have been updated (folderId removed)
    ref.invalidate(notesControllerProvider);
  }
}
