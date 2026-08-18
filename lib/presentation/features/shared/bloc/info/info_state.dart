// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

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
