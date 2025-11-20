// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumedu/data/models/planner/homework_response_model.dart';

abstract class HomeworkState {}

class HomeworkInitial extends HomeworkState {}

// Create Homework States
class HomeworkCreating extends HomeworkState {}

class HomeworkCreated extends HomeworkState {
  final HomeworkResponseModel homework;

  HomeworkCreated({required this.homework});
}

class HomeworkCreateError extends HomeworkState {
  final String message;

  HomeworkCreateError({required this.message});
}

// Fetch Homework States
class HomeworkLoading extends HomeworkState {}

class HomeworkLoaded extends HomeworkState {
  final List<HomeworkResponseModel> homeworks;

  HomeworkLoaded({required this.homeworks});
}

class HomeworkError extends HomeworkState {
  final String message;

  HomeworkError({required this.message});
}

// Fetch Single Homework States
class HomeworkByIdLoading extends HomeworkState {}

class HomeworkByIdLoaded extends HomeworkState {
  final HomeworkResponseModel homework;

  HomeworkByIdLoaded({required this.homework});
}

class HomeworkByIdError extends HomeworkState {
  final String message;

  HomeworkByIdError({required this.message});
}

// Update Homework States
class HomeworkUpdating extends HomeworkState {}

class HomeworkUpdated extends HomeworkState {
  final HomeworkResponseModel homework;

  HomeworkUpdated({required this.homework});
}

class HomeworkUpdateError extends HomeworkState {
  final String message;

  HomeworkUpdateError({required this.message});
}

// Delete Homework States
class HomeworkDeleting extends HomeworkState {}

class HomeworkDeleted extends HomeworkState {}

class HomeworkDeleteError extends HomeworkState {
  final String message;

  HomeworkDeleteError({required this.message});
}
