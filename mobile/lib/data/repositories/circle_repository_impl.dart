import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/data/models/circle_model.dart';
import 'package:mobile/domain/entities/circle.dart';
import 'package:mobile/domain/repositories/circle_repository.dart';

class CircleRepositoryImpl implements CircleRepository {
  final Dio dio;
  final String baseUrl;

  CircleRepositoryImpl(this.dio, {String? customBaseUrl}) 
      : baseUrl = customBaseUrl ?? "http://10.0.2.2:8000" {
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Use an interceptor to ensure the token is always present if it exists
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!options.headers.containsKey('Authorization')) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
    ));
  }


  @override
  Future<String> login(String email, String password) async {
    final formData = FormData.fromMap({
      "username": email,
      "password": password,
    });
    
    final response = await dio.post("$baseUrl/token", data: formData);
    final token = response.data['access_token'];
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    dio.options.headers['Authorization'] = 'Bearer $token';
    
    return token;
  }

  @override
  Future<void> register(String email, String name, String password) async {
    await dio.post(
      "$baseUrl/register",
      data: {
        "email": email,
        "name": name,
        "password": password,
      },
    );
  }

  @override
  Future<UbuntuUser> getMe() async {
    final response = await dio.get("$baseUrl/users/me");
    return UserModel.fromJson(response.data);
  }


  @override
  Future<List<Circle>> getCircles() async {
    final response = await dio.get("$baseUrl/circles");
    return (response.data as List).map((json) => CircleModel.fromJson(json)).toList();
  }

  @override
  Future<Circle> getCircle(String circleId) async {
    final response = await dio.get("$baseUrl/circles/$circleId");
    return CircleModel.fromJson(response.data);
  }

  @override
  Future<void> joinCircle(String circleId, String userId) async {
    await dio.post(
      "$baseUrl/circles/$circleId/join",
      queryParameters: {"user_id": userId},
    );
  }

  @override
  Future<UbuntuUser> getUser(String userId) async {
    final response = await dio.get("$baseUrl/users/$userId");
    return UserModel.fromJson(response.data);
  }

  @override
  Future<String?> processPayment(String circleId, String userId, double amount, {String currency = "NGN"}) async {
    final response = await dio.post(
      "$baseUrl/circles/$circleId/pay",
      queryParameters: {
        "user_id": userId,
        "amount": amount,
        "currency": currency,
      },
    );
    return response.data['transaction_ref'];
  }

  @override
  Future<double> getExchangeRate() async {
    final response = await dio.get("$baseUrl/exchange-rate");
    return (response.data['rate'] as num).toDouble();
  }

  @override
  Future<UbuntuUser> getTrustPrediction(String userId) async {
    final response = await dio.post(
      "$baseUrl/predict-trust",
      queryParameters: {"user_id": userId},
    );
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> createCircle({
    required String name,
    required double amount,
    required String frequency,
    required int maxMembers,
    required String creatorId,
    bool allowXb = false,
  }) async {
    await dio.post(
      "$baseUrl/circles/create",
      data: {
        "name": name,
        "contribution_amount": amount,
        "frequency": frequency,
        "max_members": maxMembers,
        "is_cross_border_allowed": allowXb,
      },
    );
  }

  @override
  Future<void> verifyKyc(String userId, String bvn) async {
    await dio.post(
      "$baseUrl/users/verify-kyc",
      queryParameters: {"bvn": bvn},
    );
  }

  @override
  Future<void> processPayout(String circleId, String bankCode, String accountNo, String currency) async {
    await dio.post(
      "$baseUrl/circles/$circleId/payout",
      queryParameters: {
        "bank_code": bankCode,
        "account_no": accountNo,
        "target_currency": currency,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getBanks() async {
    final response = await dio.get("$baseUrl/banks");
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> accountLookup(String bankCode, String accountNo) async {
    final response = await dio.post(
      "$baseUrl/users/account-lookup",
      queryParameters: {"bank_code": bankCode, "account_no": accountNo},
    );
    return response.data;
  }
}

