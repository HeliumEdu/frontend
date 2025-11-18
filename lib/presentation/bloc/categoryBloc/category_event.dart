import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchCategoriesEvent extends CategoryEvent {
  final int? course;
  final String? title;

  const FetchCategoriesEvent({this.course, this.title});

  @override
  List<Object?> get props => [course, title];
}
