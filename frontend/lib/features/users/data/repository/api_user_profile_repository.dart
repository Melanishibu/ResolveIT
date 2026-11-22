import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/data/datasource/users_remote_datasource.dart';
import 'package:resolveit/features/users/domain/entity/user_profile.dart';
import 'package:resolveit/features/users/domain/repository/user_profile_repository.dart';

/// Implements [UserProfileRepository] via REST.
final class ApiUserProfileRepository implements UserProfileRepository {
  ApiUserProfileRepository(this._remote);

  final UsersRemoteDataSource _remote;

  @override
  Future<Result<UserProfile>> getMyProfile() async {
    try {
      final json = await _remote.getMyProfile();
      final profile = userProfileFromJson(json);
      return profile == null ? Failure(ApiFailure.unknown()) : Success(profile);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}
