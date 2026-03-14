// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/repositories/note_repository_impl.dart';
import 'package:heliumapp/data/sources/note_remote_data_source.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/notes/views/note_add_screen.dart';
import 'package:heliumapp/presentation/features/notes/widgets/notes_data_grid.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

class NotebookScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();

  NotebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NoteBloc(
        noteRepository: NoteRepositoryImpl(
          remoteDataSource: NoteRemoteDataSourceImpl(dioClient: _dioClient),
        ),
      ),
      child: const _NotebookProvidedScreen(),
    );
  }
}

class _NotebookProvidedScreen extends StatefulWidget {
  const _NotebookProvidedScreen();

  @override
  State<_NotebookProvidedScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends BasePageScreenState<_NotebookProvidedScreen> {
  static const _savedNotebookFilterStateKey = 'saved_notebook_filter_state';
  static const _savedRowsPerPageKey = 'saved_rows_per_page';

  @override
  String get screenTitle => 'Notebook';

  @override
  IconData get icon => Icons.library_books;

  @override
  ScreenType get screenType => ScreenType.page;

  @override
  bool get showActionButton => true;

  @override
  VoidCallback? get actionButtonCallback => _createNewNote;

  List<NoteModel> _notes = [];
  String? _searchQuery;
  final Set<String> _filterEntityTypes = {};
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  bool _notesReady = false;
  bool _filterStateRestored = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  @override
  Future<UserSettingsModel?> loadSettings() {
    return super.loadSettings().then((settings) {
      if (!mounted || settings == null) return settings;
      _restoreFilterStateIfEnabled(settings);
      _filterStateRestored = true;
      _checkReadyToShow();
      return settings;
    });
  }

  void _checkReadyToShow() {
    if (_filterStateRestored) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchNotes() {
    context.read<NoteBloc>().add(
      FetchNotesEvent(
        origin: EventOrigin.screen,
        forceRefresh: true,
      ),
    );
  }

  List<NoteModel> _getFilteredNotes() {
    var filtered = _notes;

    // Apply search filter (client-side)
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(query) ||
            (note.link?.linkedEntityTitle?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply entity type filters
    if (_filterEntityTypes.isNotEmpty) {
      filtered = filtered.where((note) {
        if (_filterEntityTypes.contains('standalone')) {
          if (note.link == null) return true;
        }
        if (_filterEntityTypes.contains('homework')) {
          if (note.link?.linkedEntityType == 'homework') return true;
        }
        if (_filterEntityTypes.contains('event')) {
          if (note.link?.linkedEntityType == 'event') return true;
        }
        if (_filterEntityTypes.contains('material')) {
          if (note.link?.linkedEntityType == 'material') return true;
        }
        return false;
      }).toList();
    }

    return filtered;
  }

  void _createNewNote() {
    showNoteAdd(context);
  }

  void _openNote(NoteModel note) {
    showNoteAdd(context, noteId: note.id);
  }

  void _confirmDeleteNote(BuildContext context, NoteModel note) {
    showConfirmDeleteDialog(
      parentContext: context,
      item: note,
      onDelete: (deletedNote) {
        this.context.read<NoteBloc>().add(
          DeleteNoteEvent(
            origin: EventOrigin.screen,
            noteId: deletedNote.id,
          ),
        );
      },
    );
  }

  void _saveFilterStateIfEnabled() {
    if (!(userSettings?.rememberFilterState ?? false)) return;

    final filterState = {
      'filterEntityTypes': _filterEntityTypes.toList(),
    };
    PrefService().setString(
      _savedNotebookFilterStateKey,
      jsonEncode(filterState),
    );
    PrefService().setInt(_savedRowsPerPageKey, _rowsPerPage);
  }

  void _restoreFilterStateIfEnabled(UserSettingsModel settings) {
    if (!settings.rememberFilterState) return;

    final savedRowsPerPage = PrefService().getInt(_savedRowsPerPageKey);

    final savedState = PrefService().getString(_savedNotebookFilterStateKey);
    List<dynamic>? savedEntityTypes;
    if (savedState != null && savedState.isNotEmpty) {
      try {
        final filterState = jsonDecode(savedState) as Map<String, dynamic>;
        savedEntityTypes = filterState['filterEntityTypes'] as List<dynamic>?;
      } catch (_) {
        // Ignore malformed settings and keep defaults.
      }
    }

    if (savedEntityTypes == null && savedRowsPerPage == null) return;

    setState(() {
      if (savedEntityTypes != null) {
        _filterEntityTypes.clear();
        _filterEntityTypes.addAll(savedEntityTypes!.cast<String>());
      }
      if (savedRowsPerPage != null) _rowsPerPage = savedRowsPerPage;
    });
  }

  void _openFilterMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final filterOptions = [
      (
        value: 'standalone',
        label: 'Unlinked',
        icon: Icons.link_off,
        color: context.colorScheme.onSurface,
      ),
      (
        value: 'homework',
        label: 'Assignments',
        icon: AppConstants.assignmentIcon,
        color: context.colorScheme.onSurface,
      ),
      (
        value: 'event',
        label: 'Events',
        icon: AppConstants.eventIcon,
        color: userSettings?.eventsColor ?? context.colorScheme.tertiary,
      ),
      (
        value: 'material',
        label: 'Resources',
        icon: Icons.book,
        color: userSettings?.resourceColor ?? context.colorScheme.secondary,
      ),
    ];

    showMenu(
      context: context,
      position: position,
      color: context.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: context.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatefulBuilder(
                    builder: (innerContext, setMenuState) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Filters',
                                  style: AppStyles.formText(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _filterEntityTypes.clear();
                                  });
                                  _saveFilterStateIfEnabled();
                                  setMenuState(() {});
                                },
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...filterOptions.map((option) {
                            final isChecked = _filterEntityTypes.contains(option.value);
                            return CheckboxListTile(
                              title: Row(
                                children: [
                                  Icon(
                                    option.icon,
                                    size: 18,
                                    color: option.color,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      option.label,
                                      style: AppStyles.formText(context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              value: isChecked,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _filterEntityTypes.add(option.value);
                                  } else {
                                    _filterEntityTypes.remove(option.value);
                                  }
                                });
                                _saveFilterStateIfEnabled();
                                setMenuState(() {});
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NotesError) {
            showSnackBar(context, state.message!, type: SnackType.error);
          } else if (state is NotesFetched) {
            setState(() {
              _notes = state.notes;
              _notesReady = true;
            });
          } else if (state is NoteCreated) {
            setState(() {
              _notes.add(state.note);
              Sort.byUpdatedAt(_notes);
            });
          } else if (state is NoteUpdated) {
            setState(() {
              final index = _notes.indexWhere((n) => n.id == state.note.id);
              if (index != -1) {
                _notes[index] = state.note;
                Sort.byUpdatedAt(_notes);
              }
            });
          } else if (state is NoteDeleted) {
            setState(() {
              _notes.removeWhere((n) => n.id == state.noteId);
            });
            showSnackBar(context, 'Note deleted');
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  border: Border.all(
                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                  controller: _searchController,
                  style: AppStyles.formText(context),
                  decoration: InputDecoration(
                    hintText: 'Search ...',
                    hintStyle: AppStyles.formHint(context),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = null;
                            });
                          },
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        tooltip: 'Clear',
                      );
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.isEmpty ? null : value;
                  });
                },
              ),
              ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
              final hasFilters = _filterEntityTypes.isNotEmpty;
              return IconButton.outlined(
                onPressed: () => _openFilterMenu(context),
                tooltip: 'Filters',
                icon: const Icon(Icons.filter_alt),
                style: IconButton.styleFrom(
                  backgroundColor: hasFilters
                      ? context.colorScheme.primary
                      : null,
                  foregroundColor: hasFilters
                      ? context.colorScheme.onPrimary
                      : null,
                  side: BorderSide(color: context.colorScheme.primary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<NoteBloc, NoteState>(
      builder: (context, state) {
        if (state is NotesError) {
          return ErrorCard(
            message: state.message!,
            source: 'notes_screen',
            onReload: _fetchNotes,
          );
        }

        final notesLoading = !_notesReady;
        final filteredNotes = notesLoading ? <NoteModel>[] : _getFilteredNotes();

        if (!notesLoading && filteredNotes.isEmpty) {
          return EmptyCard(
            icon: icon,
            message: _searchQuery != null || _filterEntityTypes.isNotEmpty
                ? 'No notes match your search'
                : 'Create your first note to get started',
          );
        }

        return Expanded(
          child: NotesDataGrid(
            notes: filteredNotes,
            isLoading: notesLoading,
            onNoteTap: _openNote,
            onDelete: _confirmDeleteNote,
            userSettings: userSettings,
            rowsPerPage: _rowsPerPage,
            onRowsPerPageChanged: (rowsPerPage) {
              setState(() {
                _rowsPerPage = rowsPerPage;
              });
              _saveFilterStateIfEnabled();
            },
          ),
        );
      },
    );
  }
}
