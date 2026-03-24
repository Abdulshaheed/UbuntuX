import 'package:dio/dio.dart';
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
      queryParameters: {
        "name": name,
        "contribution_amount": amount,
        "frequency": frequency,
        "max_members": maxMembers,
        "creator_id": creatorId,
        "allow_xb": allowXb,
      },
    );
  }

  @override
  Future<void> verifyKyc(String userId, String bvn) async {
    await dio.post(
      "$baseUrl/users/$userId/verify-kyc",
      queryParameters: {"bvn": bvn},
    );
  }

  @override
  Future<void> processPayout(String circleId, String userId, String bankCode, String accountNo, String currency) async {
    // Note: userId is now handled by the Backend via JWT Token. 
    // For MVP/Demo, we assume the token is set in dio.options.headers['Authorization']
    await dio.post(
      "$baseUrl/circles/$circleId/payout",
      queryParameters: {
        "bank_code": bankCode,
        "account_no": accountNo,
        "target_currency": currency,
      },
    );
  }
}

