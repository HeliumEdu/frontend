// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/core/app_exception.dart';
import 'package:heliumedu/domain/repositories/private_feed_repository.dart';
import 'package:heliumedu/presentation/bloc/privateFeedBloc/private_feed_event.dart';
import 'package:heliumedu/presentation/bloc/privateFeedBloc/private_feed_state.dart';

class PrivateFeedBloc extends Bloc<PrivateFeedEvent, PrivateFeedState> {
  final PrivateFeedRepository privateFeedRepository;

  PrivateFeedBloc({required this.privateFeedRepository})
    : super(PrivateFeedLoading()) {
    on<FetchPrivateFeedUrlsEvent>(_onFetchPrivateFeedUrls);
    on<EnablePrivateFeedsEvent>(_onEnablePrivateFeeds);
    on<DisablePrivateFeedsEvent>(_onDisablePrivateFeeds);
  }

  Future<void> _onFetchPrivateFeedUrls(
    FetchPrivateFeedUrlsEvent event,
    Emitter<PrivateFeedState> emit,
  ) async {
    emit(PrivateFeedLoading());
    try {
      print('🎯 Fetching Private Feed URLs from repository...');
      final privateFeed = await privateFeedRepository.getPrivateFeedUrls();
      print('✅ Private Feed URLs fetched successfully');
      emit(PrivateFeedLoaded(privateFeed: privateFeed));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(PrivateFeedError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(PrivateFeedError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onEnablePrivateFeeds(
    EnablePrivateFeedsEvent event,
    Emitter<PrivateFeedState> emit,
  ) async {
    emit(PrivateFeedLoading());
    try {
      print('🔧 Enabling private feeds...');
      await privateFeedRepository.enablePrivateFeeds();
      final privateFeed = await privateFeedRepository.getPrivateFeedUrls();
      print('✅ Private feeds enabled successfully');
      emit(PrivateFeedLoaded(privateFeed: privateFeed));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(PrivateFeedError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(PrivateFeedError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDisablePrivateFeeds(
    DisablePrivateFeedsEvent event,
    Emitter<PrivateFeedState> emit,
  ) async {
    emit(PrivateFeedLoading());
    try {
      print('🛑 Disabling private feeds...');
      await privateFeedRepository.disablePrivateFeeds();
      print('✅ Private feeds disabled successfully');
      emit(
        PrivateFeedDisabled(message: 'Private feeds disabled successfully!'),
      );
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(PrivateFeedError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(PrivateFeedError(message: 'An unexpected error occurred: $e'));
    }
  }
}
