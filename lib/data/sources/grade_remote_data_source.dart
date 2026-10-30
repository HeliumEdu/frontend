import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/needed_grade_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class GradeRemoteDataSource extends BaseDataSource {
  Future<List<GradeCourseGroupModel>> getGrades({bool forceRefresh = false});

  Future<NeededGradeModel> getNeededGrade({
    required int courseId,
    required int targetId,
    required double desiredGrade,
  });
}

class GradeRemoteDataSourceImpl extends GradeRemoteDataSource {
  final DioClient dioClient;

  GradeRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<GradeCourseGroupModel>> getGrades({bool forceRefresh = false}) async {
    try {
      _log.info('Fetching Grades ...');

      final response = await dioClient.dio.get(
        ApiUrl.plannerGradesUrl,
        options: forceRefresh ? dioClient.cacheService.forceRefreshOptions() : null,
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;

          if (responseMap.containsKey('course_groups') &&
              responseMap['course_groups'] is List) {
            final grades = (responseMap['course_groups'] as List)
                .map(
                  (group) => GradeCourseGroupModel.fromJson(
                    group as Map<String, dynamic>,
                  ),
                )
                .toList();

            _log.info('... fetched Grades for ${grades.length} CourseGroup(s)');
            return grades;
          } else {
            throw ServerException(
              message: 'Invalid response format: missing course_groups.',
              code: '200',
            );
          }
        } else {
          throw ServerException(
            message: 'Invalid response format: expected Map.',
            code: '200',
          );
        }
      } else {
        throw unexpectedStatus(response, 'Failed to fetch grades.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }

  @override
  Future<NeededGradeModel> getNeededGrade({
    required int courseId,
    required int targetId,
    required double desiredGrade,
  }) async {
    try {
      _log.info('Calculating needed Grade for Course $courseId ...');

      final response = await dioClient.dio.get(
        ApiUrl.plannerGradesNeededUrl,
        queryParameters: {
          'course': courseId,
          'target': targetId,
          'desired_grade': desiredGrade,
        },
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final neededGrade = NeededGradeModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          _log.info(
            '... needed Grade calculated for Course $courseId (${neededGrade.state.name})',
          );
          return neededGrade;
        } else {
          throw ServerException(
            message: 'Invalid response format: expected Map.',
            code: '200',
          );
        }
      } else {
        throw unexpectedStatus(response, 'Failed to calculate needed grade.');
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } on HeliumException {
      rethrow;
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: HeliumException.unexpectedError);
    }
  }
}
