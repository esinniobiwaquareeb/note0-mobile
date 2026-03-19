import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/usage_service.dart';

import 'notes_controller.dart';
import 'notes_editor_screen.dart';
import 'settings_screen.dart';
import 'audio_recording_screen.dart';
import '../pro/pro_screen.dart';

import 'youtube_processing_dialog.dart';
import 'folders_controller.dart';
import 'folder_details_screen.dart';
import '../onboarding/user_guide_overlay.dart';
import '../../core/theme/app_theme.dart';
import '../../data/note.dart';



final showGuideProvider = StateProvider<bool>((ref) => true);

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  int _selectedTab = 0; // 0 for All Notes, 1 for Folders
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : Row(
                children: [
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 32,
                    height: 32,
                  ),
                  const Gap(12),
                  Text(
                    'Note0',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final userAsync = ref.watch(userProvider);
              return userAsync.when(
                data: (user) {
                  final avatarUrl = user?['avatarUrl'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      child: CircleAvatar(
                        backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                        maxRadius: 18,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Icon(
                                Icons.person_outline,
                                color: isDark ? Colors.white : Colors.black54,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, st) => const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.error_outline, size: 24, color: Colors.red),
                ),
              );
            },
          ),

        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Gap(20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'All Notes',
                        icon: Icons.edit_note,
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _TabButton(
                        label: 'Folders',
                        icon: Icons.folder_open,
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedTab == 0
                    ? Builder(
                        builder: (context) {
                          final notes = notesAsync.asData?.value ?? [];
                          var displayNotes = [...notes];


                          if (_searchQuery.isNotEmpty) {
                            displayNotes = displayNotes.where((note) {
                              final title = note.title.toLowerCase();
                              final content = note.content.toLowerCase();
                              final query = _searchQuery.toLowerCase();
                              return title.contains(query) ||
                                  content.contains(query);
                            }).toList();
                          }

                          if (notesAsync.isLoading && displayNotes.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (notesAsync.hasError) {
                            return Center(
                              child: Text('Error: ${notesAsync.error}'),
                            );
                          }

                          if (displayNotes.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.note_alt_outlined,
                                    size: 64,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  const Gap(16),
                                  const Text(
                                    'No notes yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            children: [
                              Text(
                                'Ongoing',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Gap(16),
                              _AnalyzingCard(),
                              const Gap(24),
                              Text(
                                DateFormat(
                                  'EEE, MMM dd',
                                ).format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Gap(16),
                              ...displayNotes.reversed.map(
                                (note) => Dismissible(
                                  key: Key(note.id),
                                  direction: DismissDirection.horizontal,
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    color: Colors.blue,
                                    child: const Icon(Icons.drive_file_move_outlined, color: Colors.white),
                                  ),
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete_outline, color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction == DismissDirection.endToStart) {
                                      return await _confirmDelete(context);
                                    } else {
                                      _showMoveToFolderSheetForNote(context, note);
                                      return false;
                                    }
                                  },
                                  onDismissed: (direction) {
                                    if (direction == DismissDirection.endToStart) {
                                      ref.read(notesControllerProvider.notifier).deleteNote(note.id);
                                    }
                                  },
                                  child: _NoteTile(note: note),
                                ),
                              ),
                              const Gap(24),
                              FutureBuilder<bool>(
                                future: ref.read(authServiceProvider).isPro(),
                                builder: (context, snapshot) {
                                  if (snapshot.data == true) return const SizedBox.shrink();
                                  return const _ProUpgradeCard();
                                },
                              ),
                              const Gap(80),
                            ],
                          );


                        },
                      )
                    : _FoldersView(),
              ),
            ],
          ),
          if (ref.watch(showGuideProvider))
            UserGuideOverlay(
              onDismiss: () =>
                  ref.read(showGuideProvider.notifier).state = false,
            ),
        ],
      ),
      bottomNavigationBar: _BottomActionArea(
        onRecord: () => _showNewNoteSheet(context),
        onNewNote: () => _showNewNoteSheet(context),
      ),
    );
  }

  void _showNewNoteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewNoteSheet(
        onRecord: _startRecording,
        onUpload: _uploadFile,
        onYouTube: () => _processYouTube(context),
      ),
    );
  }

  Future<void> _startRecording() async {
    final usageService = ref.read(usageServiceProvider);
    final authService = ref.read(authServiceProvider);

    final isPro = await authService.isPro();

    final canRecord = await usageService.canRecord(isPro);

    if (!canRecord) {
      if (mounted) {
        _showLimitReachedDialog(context);
      }
      return;
    }

    if (!mounted) return;
    final path = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => const AudioRecordingScreen()),
    );

    if (path != null) {
      _showSuccess('Recording completed. Analyzing with AI...');

      try {
        final note = await ref
            .read(notesControllerProvider.notifier)
            .uploadRecording(path);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => NotesEditorScreen(noteId: note.id)),
          );
        }
      } catch (e) {
        if (mounted) {
          if (e.toString().contains('limit reached')) {
            _showLimitReachedDialog(context);
          } else {
            _showError(e.toString());
          }
        }
      }
    }

  }

  void _showLimitReachedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.blue, size: 32),
            ),
            const Gap(16),
            const Text(
              'Limit Reached',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
          ],
        ),
        content: const Text(
          'You\'ve experienced Note0\'s industrial transcription! To save permanently or record more, please sign in or upgrade to Pro.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey),
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final authService = ref.read(authServiceProvider);
                    final result = await authService.signInWithGoogle();
                    if (result != null && mounted) {
                      _showSuccess('Welcome to Note0!');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const Gap(12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Upgrade for Unlimited Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const Gap(8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }


  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'mp3', 'wav'],
    );
    if (result != null) {
      _showSuccess('File uploaded. Analyzing...');
    }
  }

  Future<void> _processYouTube(BuildContext context) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => const YouTubeProcessingDialog(),
    );
    if (result != null) {
      _showSuccess('Video integrated. Analyzing...');
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Note?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMoveToFolderSheetForNote(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoveToFolderSheetInList(note: note),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white12 : Colors.grey[200])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white12 : Colors.grey[300]!)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.grey,
            ),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.withOpacity(0.5),
                  ),
                ),
              ),
              const Icon(Icons.auto_awesome, size: 12, color: Colors.blue),
            ],
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Note0 is analyzing...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Gap(2),
              Text(
                'Extracting key concepts & summary',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotesEditorScreen(noteId: note.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Hero(
                  tag: 'note-icon-${note.id}',
                  child: Icon(
                    note.title.contains('Noise')
                        ? Icons.speaker_group
                        : Icons.volume_up,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd').format(note.updatedAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      note.content.isEmpty
                          ? 'The audio recording has been analyzed...'
                          : note.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionArea extends StatelessWidget {
  const _BottomActionArea({required this.onRecord, required this.onNewNote});
  final VoidCallback onRecord;
  final VoidCallback onNewNote;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              label: 'Record',
              icon: Icons.mic,
              color: Colors.redAccent,
              onTap: onRecord,
            ),
          ),
          const Gap(12),
          Expanded(
            child: _ActionBtn(
              label: 'New Note',
              icon: Icons.add,
              color: isDark ? Colors.white : Colors.black,
              textColor: isDark ? Colors.black : Colors.white,
              onTap: onNewNote,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor ?? Colors.white, size: 20),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoldersView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersControllerProvider);
    final notesAsync = ref.watch(notesControllerProvider);

    return foldersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (folders) {
        final notes = notesAsync.asData?.value ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: folders.length + 1,
          itemBuilder: (context, index) {
            if (index == folders.length) {
              return _AddFolderCard(
                onTap: () => _showCreateFolderDialog(context, ref),
              );
            }
            final folder = folders[index];
            final count = notes.where((n) => n.folderId == folder.id).length;
            return _FolderCard(
              folder: folder,
              count: count,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FolderDetailsScreen(folder: folder),
                ),
              ),
              onLongPress: () => _showFolderOptions(context, ref, folder),
            );
          },
        );
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref
                    .read(foldersControllerProvider.notifier)
                    .createFolder(
                      nameController.text,
                      Icons.folder.codePoint,
                      Colors.blue.value,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showFolderOptions(BuildContext context, WidgetRef ref, dynamic folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Folder',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                ref
                    .read(foldersControllerProvider.notifier)
                    .deleteFolder(folder.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFolderCard extends StatelessWidget {
  const _AddFolderCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey[400], size: 32),
            const Gap(8),
            Text(
              'New Folder',
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.count,
    required this.onTap,
    required this.onLongPress,
  });

  final dynamic folder;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(folder.colorValue);
    final iconCode = folder.iconCode;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconData(iconCode, fontFamily: 'MaterialIcons'),
                color: color,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Gap(4),
                Text(
                  '$count notes',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewNoteSheet extends StatelessWidget {
  const _NewNoteSheet({
    required this.onRecord,
    required this.onUpload,
    required this.onYouTube,
  });

  final VoidCallback onRecord;
  final VoidCallback onUpload;
  final VoidCallback onYouTube;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(24),
          _NewNoteOption(
            icon: Icons.mic_none,
            iconColor: Colors.blue,
            iconBg: Colors.blue.withOpacity(0.1),
            title: 'Record',
            subtitle: 'Record and transcribe audio',
            onTap: () {
              Navigator.pop(context);
              onRecord();
            },
          ),
          const Gap(16),
          _NewNoteOption(
            icon: Icons.upload_file_outlined,
            iconColor: Colors.orange,
            iconBg: Colors.orange.withOpacity(0.1),
            title: 'Upload Audio',
            subtitle: 'Upload local audio files',
            onTap: () {
              Navigator.pop(context);
              onUpload();
            },
          ),
          const Gap(16),
          _NewNoteOption(
            icon: Icons.play_circle_outline,
            iconColor: Colors.red,
            iconBg: Colors.red.withOpacity(0.1),
            title: 'YouTube Video',
            subtitle: 'Paste video link to analyze',
            onTap: () {
              Navigator.pop(context);
              onYouTube();
            },
          ),
          const Gap(32),
        ],
      ),
    );
  }
}

class _NewNoteOption extends StatelessWidget {
  const _NewNoteOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _MoveToFolderSheetInList extends ConsumerWidget {
  const _MoveToFolderSheetInList({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Move to Folder',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          foldersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
            data: (folders) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.not_interested),
                      title: const Text('No Folder'),
                      trailing: note.folderId == null
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () {
                        ref
                            .read(notesControllerProvider.notifier)
                            .moveToFolder(note.id, null);
                        Navigator.pop(context);
                        ToastUtils.showSuccess(
                          context,
                          'Note removed from folder',
                        );
                      },
                    ),
                    ...folders.map(
                      (folder) => ListTile(
                        leading: Icon(
                          IconData(
                            folder.iconCode,
                            fontFamily: 'MaterialIcons',
                          ),
                          color: Color(folder.colorValue),
                        ),
                        title: Text(folder.name),
                        trailing: note.folderId == folder.id
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () {
                          ref
                              .read(notesControllerProvider.notifier)
                              .moveToFolder(note.id, folder.id);
                          Navigator.pop(context);
                          ToastUtils.showSuccess(
                            context,
                            'Note moved to ${folder.name}',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Gap(24),
        ],
      ),
    );
  }
}

class _ProUpgradeCard extends StatelessWidget {
  const _ProUpgradeCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(isDark ? 0.05 : 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, color: Colors.blue, size: 20),
              ),
              const Gap(12),
              const Text(
                'Unlock Pro Tools',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            'Get unlimited recordings, advanced AI analysis, and multi-device sync with Note0 Pro.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Upgrade Now',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
