// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/domain/repositories/info_repository.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.bloc');

class InfoBloc extends Bloc<InfoEvent, InfoState> {
  final InfoRepository infoRepository;

  InfoBloc({required this.infoRepository}) : super(InfoInitial()) {
    on<LoadInfoEvent>(_onLoadInfo);
  }

  Future<void> _onLoadInfo(
    LoadInfoEvent event,
    Emitter<InfoState> emit,
  ) async {
    emit(InfoLoading());

    try {
      final info = await infoRepository.getInfo();
      emit(InfoLoaded(info: info));
    } on HeliumException catch (e) {
      _log.warning('Failed to load /info/: ${e.message}');
      emit(InfoLoadFailed(message: e.displayMessage));
    } catch (e, s) {
      _log.severe('Unexpected error loading /info/', e, s);
      emit(InfoLoadFailed(message: 'An unexpected error occurred.'));
    }
  }
}
