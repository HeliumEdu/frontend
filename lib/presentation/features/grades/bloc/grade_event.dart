// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

abstract class GradeEvent {}

class FetchGradeScreenDataEvent extends GradeEvent {
  final bool forceRefresh;

  FetchGradeScreenDataEvent({this.forceRefresh = false});
}

/// Clears all grade state. Dispatched on logout so per-user data does not
/// carry into the next session.
class ResetGradesEvent extends GradeEvent {}
