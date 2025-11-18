import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/core/app_exception.dart';
import 'package:helium_student_flutter/domain/repositories/ical_feed_repository.dart';
import 'package:helium_student_flutter/presentation/bloc/iCalFeedBloc/ical_feed_event.dart';
import 'package:helium_student_flutter/presentation/bloc/iCalFeedBloc/ical_feed_state.dart';

class ICalFeedBloc extends Bloc<ICalFeedEvent, ICalFeedState> {
  final ICalFeedRepository iCalFeedRepository;

  ICalFeedBloc({required this.iCalFeedRepository}) : super(ICalFeedInitial()) {
    on<FetchICalFeedUrlsEvent>(_onFetchICalFeedUrls);
    on<EnablePrivateFeedsEvent>(_onEnablePrivateFeeds);
    on<DisablePrivateFeedsEvent>(_onDisablePrivateFeeds);
  }

  Future<void> _onFetchICalFeedUrls(
    FetchICalFeedUrlsEvent event,
    Emitter<ICalFeedState> emit,
  ) async {
    emit(ICalFeedLoading());
    try {
      print('🎯 Fetching iCal feed URLs from repository...');
      final icalFeed = await iCalFeedRepository.getICalFeedUrls();
      print('✅ iCal feed URLs fetched successfully');
      emit(ICalFeedLoaded(icalFeed: icalFeed));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(ICalFeedError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(ICalFeedError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onEnablePrivateFeeds(
    EnablePrivateFeedsEvent event,
    Emitter<ICalFeedState> emit,
  ) async {
    emit(ICalFeedEnabling());
    try {
      print('🔧 Enabling private feeds...');
      await iCalFeedRepository.enablePrivateFeeds();
      print('✅ Private feeds enabled successfully');
      emit(ICalFeedEnabled(message: 'Private feeds enabled successfully!'));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(ICalFeedError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(ICalFeedError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDisablePrivateFeeds(
    DisablePrivateFeedsEvent event,
    Emitter<ICalFeedState> emit,
  ) async {
    emit(ICalFeedDisabling());
    try {
      print('🛑 Disabling private feeds...');
      await iCalFeedRepository.disablePrivateFeeds();
      print('✅ Private feeds disabled successfully');
      emit(ICalFeedDisabled(message: 'Private feeds disabled successfully!'));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(ICalFeedError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(ICalFeedError(message: 'An unexpected error occurred: $e'));
    }
  }
}
