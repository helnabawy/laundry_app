import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

typedef VerifyOtpResponse = ({String token, AppUser user});

abstract interface class AuthRemoteDataSource {
  Future<void> requestOtp(String phone);
  Future<VerifyOtpResponse> verifyOtp(String phone, String code);
  Future<AppUser> getMe();
  Future<AppUser> updateProfile(String fullName);
}

class AuthApiDataSource implements AuthRemoteDataSource {
  const AuthApiDataSource(this._api);

  final ApiClient _api;

  @override
  Future<void> requestOtp(String phone) =>
      _api.post(ApiEndpoints.requestOtp, data: {'phone': phone});

  @override
  Future<VerifyOtpResponse> verifyOtp(String phone, String code) async {
    final json =
        await _api.post(
              ApiEndpoints.verifyOtp,
              data: {'phone': phone, 'code': code},
            )
            as Map<String, dynamic>;
    return (
      token: json['token'] as String,
      user: AppUserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  @override
  Future<AppUser> getMe() async {
    final json = await _api.get(ApiEndpoints.me);
    return AppUserModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<AppUser> updateProfile(String fullName) async {
    final json = await _api.put(
      ApiEndpoints.profile,
      data: {'fullName': fullName},
    );
    return AppUserModel.fromJson(json as Map<String, dynamic>);
  }
}
