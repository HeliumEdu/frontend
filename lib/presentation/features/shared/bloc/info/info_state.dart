// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/info_model.dart';

abstract class InfoState {}

class InfoInitial extends InfoState {}

class InfoLoading extends InfoState {}

class InfoLoaded extends InfoState {
  final InfoModel info;

  InfoLoaded({required this.info});
}

class InfoLoadFailed extends InfoState {
  final String? message;

  InfoLoadFailed({this.message});
}
