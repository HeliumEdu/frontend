import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/notebook/views/note_add_screen.dart';
import 'package:heliumapp/presentation/features/notebook/widgets/notebook_data_grid.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/shadow_container.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/search_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';


class NotebookScreen extends StatelessWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context) => const _NotebookProvidedScreen();
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
  bool get enablePrint => true;


  @override
  IconData get icon => Icons.library_books;

  @override
  ScreenType get screenType => ScreenType.page;

  @override
  bool get showActionButton => true;

  @override
  VoidCallback? get actionButtonCallback => _createNewNote;

  static const _contentSearchDebounce = Duration(milliseconds: 400);
  static const _contentSearchMinLength = 2;

  List<NoteModel> _notes = [];
  String? _searchQuery;
  bool _searchNoteContent = false;
  Timer? _contentSearchTimer;
  String? _loadingContentSearchQuery;
  String? _loadedContentSearchQuery;
  Set<int>? _contentSearchMatchIds;
  bool _contentSearchErrorShown = false;
  final Set<String> _filterEntityTypes = {};
  bool _shownOnCalendar = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _rowsPerPage = 10;
  bool _notesReady = false;

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
      setState(() {
        isLoading = false;
      });
      return settings;
    });
  }

  @override
  void dispose() {
    _contentSearchTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NotesError && state.origin == EventOrigin.screen) {
            setState(() {
              isLoading = false;
              screenError = state.message ?? HeliumException.unexpectedError;
            });
          } else if (state is NotesError &&
              state.origin == EventOrigin.subScreen &&
              _loadingContentSearchQuery != null) {
            setState(() {
              _loadingContentSearchQuery = null;
            });
            if (!_contentSearchErrorShown) {
              _contentSearchErrorShown = true;
              showSnackBar(context, state.message!, type: SnackType.error);
            }
          } else if (state is NotesError && state.origin != EventOrigin.screen && state.origin != EventOrigin.subScreen) {
            if (!isShowingErrorCard) {
              showSnackBar(context, state.message!, type: SnackType.error);
            }
          } else if (state is NotesFetched && state.origin == EventOrigin.subScreen) {
            _onContentSearchResults(state);
          } else if (state is NotesFetched) {
            setState(() {
              _notes = state.notes;
              _notesReady = true;
              screenError = null;
            });
          } else if (state is NoteCreated) {
            setState(() {
              _notes = [..._notes, state.note];
              Sort.byUpdatedAt(_notes);
            });
            _refreshContentSearch();
          } else if (state is NoteUpdated) {
            setState(() {
              final updated = List<NoteModel>.from(_notes);
              final index = updated.indexWhere((n) => n.id == state.note.id);
              if (index != -1) {
                updated[index] = state.note;
                Sort.byUpdatedAt(updated);
                _notes = updated;
              }
            });
            _refreshContentSearch();
          } else if (state is NoteDeleted) {
            setState(() {
              _notes = _notes.where((n) => n.id != state.noteId).toList();
              _contentSearchMatchIds?.remove(state.noteId);
            });
            showSnackBar(context, 'Note deleted.');
          }
        },
      ),
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileUpdated) {
            setState(() {
              userSettings = state.user.settings;
            });
          }
        },
      ),
      BlocListener<PlannerItemBloc, PlannerItemState>(
        listener: (context, state) {
          if (state is AllEventsDeleted) {
            setState(() {
              _notes = _notes.map((note) {
                if (note.events.isEmpty) return note;
                return note.copyWith(events: [], linkedEntityType: '');
              }).toList();
            });
          } else if (state is HomeworkUpdated) {
            setState(() {
              final updated = List<NoteModel>.from(_notes);
              final index = updated.indexWhere(
                (n) => n.homework.contains(state.homework.id),
              );
              if (index != -1) {
                updated[index] = updated[index].copyWith(
                  linkedEntityTitle: state.homework.title,
                );
                _notes = updated;
              }
            });
          } else if (state is EventUpdated) {
            setState(() {
              final updated = List<NoteModel>.from(_notes);
              final index = updated.indexWhere(
                (n) => n.events.contains(state.event.id),
              );
              if (index != -1) {
                updated[index] = updated[index].copyWith(
                  linkedEntityTitle: state.event.title,
                );
                _notes = updated;
              }
            });
          } else if (state is HomeworkDeleted) {
            setState(() {
              final updated = List<NoteModel>.from(_notes);
              final index = updated.indexWhere(
                (n) => n.homework.contains(state.id),
              );
              if (index != -1) {
                updated[index] = updated[index].copyWith(
                  homework: updated[index].homework
                      .where((id) => id != state.id)
                      .toList(),
                  linkedEntityType: '',
                );
                _notes = updated;
              }
            });
          } else if (state is EventDeleted) {
            setState(() {
              final updated = List<NoteModel>.from(_notes);
              final index = updated.indexWhere(
                (n) => n.events.contains(state.id),
              );
              if (index != -1) {
                updated[index] = updated[index].copyWith(
                  events: updated[index].events
                      .where((id) => id != state.id)
                      .toList(),
                  linkedEntityType: '',
                );
                _notes = updated;
              }
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return PrintHidden(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShadowContainer(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
          child: SizedBox(
            height: 48,
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
                        child: TextFieldTapRegion(
                          onTapOutside: Responsive.isMobile(context)
                              ? (_) => _searchFocusNode.unfocus()
                              : null,
                          child: TextField(
                            focusNode: _searchFocusNode,
                            controller: _searchController,
                            style: AppStyles.formText(context),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'Search ...',
                              hintStyle: AppStyles.formHint(context),
                              prefixIcon: _buildSearchPrefixIcon(context),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _searchController,
                                    builder: (context, value, _) {
                                      if (value.text.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return _buildSearchFieldButton(
                                        context,
                                        icon: Icons.close,
                                        tooltip: 'Clear',
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchQueryChanged(null);
                                        },
                                      );
                                    },
                                  ),
                                  _buildSearchFieldButton(
                                    context,
                                    icon: Icons.manage_search,
                                    tooltip: _searchNoteContent
                                        ? 'Stop searching note content'
                                        : 'Also search note content',
                                    onPressed: _toggleContentSearch,
                                    isActive: _searchNoteContent,
                                  ),
                                ],
                              ),
                            ),
                            onChanged: (value) {
                              _onSearchQueryChanged(value.isEmpty ? null : value);
                            },
                            onSubmitted: (_) =>
                                _scheduleContentSearch(immediately: true),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final hasFilters =
                        _filterEntityTypes.isNotEmpty || _shownOnCalendar;
                    return IconButton.outlined(
                      onPressed: () => _openFilterMenu(context),
                      tooltip: 'Filters',
                      icon: const Icon(Icons.filter_alt),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          ),
        ),
      ),
    );
  }


  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<NoteBloc, NoteState>(
      builder: (context, state) {
        if (state is NotesError && state.origin == EventOrigin.screen) {
          return ErrorCard(
            message: state.message!,
            source: 'notes_screen',
            onReload: reloadPage,
          );
        }

        final notesLoading = !_notesReady;
        final hasAnyNotes = _notes.isNotEmpty;
        final filteredNotes = (notesLoading || !hasAnyNotes)
            ? <NoteModel>[]
            : _getFilteredNotes();
        final offerContentSearch = hasAnyNotes &&
            filteredNotes.isEmpty &&
            !_searchNoteContent &&
            _hasSearchQuery;

        return NotebookDataGrid(
          notes: filteredNotes,
          isLoading: notesLoading,
          hasAnyNotes: hasAnyNotes,
          emptyMessage: 'No notes match the applied filters or search',
          emptyAction: offerContentSearch
              ? TextButton.icon(
                  onPressed: _toggleContentSearch,
                  icon: const Icon(Icons.manage_search),
                  label: const Text('Search note content'),
                )
              : null,
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
        );
      },
    );
  }

  void _fetchNotes() {
    context.read<NoteBloc>().add(
      FetchNotesEvent(
        origin: EventOrigin.screen,
        shownOnCalendar: _shownOnCalendar,
      ),
    );
    _refreshContentSearch(immediately: true);
  }

  bool get _hasSearchQuery => _searchQuery?.trim().isNotEmpty ?? false;

  String get _contentSearchQuery =>
      SearchHelper.normalizeQuery(_searchQuery ?? '');

  bool get _isContentSearchWorthRequesting =>
      _searchNoteContent &&
      _contentSearchQuery.length >= _contentSearchMinLength &&
      SearchHelper.hasTerms(_contentSearchQuery);

  Widget _buildSearchFieldButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 20,
        color: isActive
            ? context.colorScheme.primary
            : context.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      tooltip: tooltip,
    );
  }

  Widget _buildSearchPrefixIcon(BuildContext context) {
    final color = context.colorScheme.onSurface.withValues(alpha: 0.4);
    if (_loadingContentSearchQuery == null) {
      return Icon(Icons.search, color: color);
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: LoadingIndicator(
          size: 16,
          strokeWidth: 2,
          color: color,
          expanded: false,
        ),
      ),
    );
  }

  void _onSearchQueryChanged(String? query) {
    setState(() {
      _searchQuery = query;
      if (_contentSearchQuery != _loadedContentSearchQuery) {
        _loadedContentSearchQuery = null;
        _contentSearchMatchIds = null;
      }
    });
    _scheduleContentSearch();
  }

  void _toggleContentSearch() {
    setState(() {
      _searchNoteContent = !_searchNoteContent;
      _loadedContentSearchQuery = null;
      _contentSearchMatchIds = null;
    });
    _saveFilterStateIfEnabled();
    _scheduleContentSearch(immediately: true);
  }

  void _refreshContentSearch({bool immediately = false}) {
    _loadedContentSearchQuery = null;
    _scheduleContentSearch(immediately: immediately);
  }

  void _scheduleContentSearch({bool immediately = false}) {
    _contentSearchTimer?.cancel();
    if (!_isContentSearchWorthRequesting) {
      _contentSearchErrorShown = false;
      if (_loadingContentSearchQuery != null || _contentSearchMatchIds != null) {
        setState(() {
          _loadingContentSearchQuery = null;
          _contentSearchMatchIds = null;
        });
      }
      return;
    }
    if (immediately) {
      _runContentSearch();
      return;
    }
    _contentSearchTimer = Timer(_contentSearchDebounce, _runContentSearch);
  }

  void _runContentSearch() {
    if (!mounted) return;
    final query = _contentSearchQuery;
    if (query == _loadingContentSearchQuery || query == _loadedContentSearchQuery) {
      return;
    }
    setState(() {
      _loadingContentSearchQuery = query;
    });
    context.read<NoteBloc>().add(
      FetchNotesEvent(
        origin: EventOrigin.subScreen,
        search: query,
        shownOnCalendar: _shownOnCalendar,
      ),
    );
  }

  void _onContentSearchResults(NotesFetched state) {
    if (state.search != _loadingContentSearchQuery) return;
    final isCurrent = _searchNoteContent && state.search == _contentSearchQuery;
    _contentSearchErrorShown = false;
    setState(() {
      _loadingContentSearchQuery = null;
      _loadedContentSearchQuery = isCurrent ? state.search : null;
      _contentSearchMatchIds =
          isCurrent ? state.notes.map((note) => note.id).toSet() : null;
    });
  }

  List<NoteModel> _getFilteredNotes() {
    var filtered = _notes;

    if (_hasSearchQuery) {
      final contentMatchIds = _contentSearchMatchIds;
      filtered = filtered.where((note) {
        if (contentMatchIds != null) return contentMatchIds.contains(note.id);
        return SearchHelper.matchesAny(
          [note.title, note.linkedEntityTitle],
          _searchQuery!,
        );
      }).toList();
    }

    if (_filterEntityTypes.isNotEmpty) {
      filtered = filtered.where((note) {
        if (_filterEntityTypes.contains('standalone')) {
          if (note.isStandalone) return true;
        }
        if (_filterEntityTypes.contains('homework')) {
          if (note.linkedEntityType == 'homework') return true;
        }
        if (_filterEntityTypes.contains('event')) {
          if (note.linkedEntityType == 'event') return true;
        }
        if (_filterEntityTypes.contains('resource')) {
          if (note.linkedEntityType == 'resource') return true;
        }
        return false;
      }).toList();
    }

    return filtered;
  }

  void _saveFilterStateIfEnabled() {
    if (!(userSettings?.rememberFilterState ?? FallbackConstants.defaultRememberFilterState)) return;

    final filterState = {
      'filterEntityTypes': _filterEntityTypes.toList(),
      'shownOnCalendar': _shownOnCalendar,
      'searchNoteContent': _searchNoteContent,
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
    bool? savedExcludeHiddenGroups;
    bool? savedSearchNoteContent;
    if (savedState != null && savedState.isNotEmpty) {
      try {
        final filterState = jsonDecode(savedState) as Map<String, dynamic>;
        savedEntityTypes = filterState['filterEntityTypes'] as List<dynamic>?;
        savedExcludeHiddenGroups =
            filterState['shownOnCalendar'] as bool?;
        savedSearchNoteContent = filterState['searchNoteContent'] as bool?;
      } catch (_) {}
    }

    if (savedEntityTypes == null &&
        savedExcludeHiddenGroups == null &&
        savedSearchNoteContent == null &&
        savedRowsPerPage == null) {
      return;
    }

    setState(() {
      if (savedEntityTypes != null) {
        _filterEntityTypes.clear();
        _filterEntityTypes.addAll(savedEntityTypes.cast<String>());
      }
      if (savedExcludeHiddenGroups != null) {
        _shownOnCalendar = savedExcludeHiddenGroups;
      }
      if (savedSearchNoteContent != null) {
        _searchNoteContent = savedSearchNoteContent;
      }
      if (savedRowsPerPage != null) _rowsPerPage = savedRowsPerPage;
    });

    if (savedExcludeHiddenGroups == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchNotes();
      });
    }
  }

  void _openFilterMenu(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    Widget buildContent(BuildContext context, StateSetter setMenuState) {
      final filterOptions = [
        (
          value: 'standalone',
          label: 'Standalone',
          iconWidget: Icon(
            Icons.link_off,
            size: 18,
            color: context.colorScheme.onSurface,
          ),
        ),
        (
          value: 'homework',
          label: 'Assignments',
          iconWidget: PlannerTypeColors.rainbowIcon(AppConstants.assignmentIcon),
        ),
        (
          value: 'event',
          label: 'Events',
          iconWidget: Icon(
            AppConstants.eventIcon,
            size: 18,
            color: PlannerTypeColors.events(userSettings?.eventsColor),
          ),
        ),
        (
          value: 'resource',
          label: 'Resources',
          iconWidget: Icon(
            Icons.book_outlined,
            size: 18,
            color: userSettings?.resourceColor ?? FallbackConstants.defaultResourceColor,
          ),
        ),
      ];

      return Material(
        color: context.colorScheme.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * AppConstants.bottomSheetMaxHeightFactor,
          ),
          child: SingleChildScrollView(
            child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                    final wasExcluding = _shownOnCalendar;
                    _filterEntityTypes.clear();
                    _shownOnCalendar = false;
                    _saveFilterStateIfEnabled();
                    setMenuState(() {});
                    // Defer outer setState because setMenuState may still be
                    // executing its rebuild when this callback runs
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {});
                        if (wasExcluding) _fetchNotes();
                      }
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...filterOptions.map((option) {
              final isChecked = _filterEntityTypes.contains(option.value);
              return HeliumCheckboxListTile(
                title: Row(
                  children: [
                    option.iconWidget,
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
                  if (value == true) {
                    _filterEntityTypes.add(option.value);
                  } else {
                    _filterEntityTypes.remove(option.value);
                  }
                  _saveFilterStateIfEnabled();
                  setMenuState(() {});
                  // Defer outer setState because setMenuState may still be
                  // executing its rebuild when this callback runs
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {});
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
            const Divider(height: 16),
            HeliumCheckboxListTile(
              title: Row(
                children: [
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 18,
                    color: context.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hide notes linked to hidden groups',
                      style: AppStyles.formText(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              value: _shownOnCalendar,
              onChanged: (value) {
                _shownOnCalendar = value ?? false;
                _saveFilterStateIfEnabled();
                setMenuState(() {});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {});
                    _fetchNotes();
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
            ),
          ),
        ),
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => StatefulBuilder(builder: buildContent),
      );
    } else {
      final RenderBox button = context.findRenderObject() as RenderBox;
      final RenderBox overlay =
          Overlay.of(context, rootOverlay: true).context.findRenderObject() as RenderBox;
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

      showMenu(
        context: context,
        position: position,
        color: context.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // Open on the root navigator so the popup's tap-outside barrier
        // covers the header — tapping anywhere on the page (including the
        // header) dismisses the menu.
        useRootNavigator: true,
        items: [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(builder: buildContent),
          ),
        ],
      );
    }
  }

  void _createNewNote() {
    showNoteAdd(context, isNew: true);
  }

  void _openNote(NoteModel note) {
    showNoteAdd(context, isNew: false, noteId: note.id);
  }

  void _confirmDeleteNote(BuildContext context, NoteModel note) {
    showConfirmDeleteDialog(
      parentContext: context,
      item: note,
      label: note.title,
      onDelete: (deletedNote) {
        this.context.read<NoteBloc>().add(
          DeleteNoteEvent(
            origin: EventOrigin.dialog,
            noteId: deletedNote.id,
          ),
        );
      },
    );
  }
}
