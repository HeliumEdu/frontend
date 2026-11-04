import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/domain/repositories/info_repository.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.bloc');

/// A refresh keeps the loaded info in place, even when it fails.
class InfoBloc extends Bloc<InfoEvent, InfoState> {
  final InfoRepository infoRepository;

  InfoBloc({required this.infoRepository}) : super(InfoInitial()) {
    on<LoadInfoEvent>(_onLoadInfo);
  }

  Future<void> _onLoadInfo(
    LoadInfoEvent event,
    Emitter<InfoState> emit,
  ) async {
    final isRefresh = state is InfoLoaded;
    if (!isRefresh) {
      emit(InfoLoading());
    }

    try {
      final info = await infoRepository.getInfo();
      emit(InfoLoaded(info: info));
    } on HeliumException catch (e) {
      _log.warning('Failed to load /info/: ${e.runtimeType} code=${e.code}');
      if (!isRefresh) {
        emit(InfoLoadFailed(message: e.displayMessage));
      }
    } catch (e, s) {
      _log.severe('Unexpected error loading /info/', e, s);
      if (!isRefresh) {
        emit(InfoLoadFailed(message: HeliumException.unexpectedError));
      }
    }
  }
}
