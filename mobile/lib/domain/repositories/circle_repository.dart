import 'package:mobile/domain/entities/circle.dart';

abstract class CircleRepository {
  Future<List<Circle>> getCircles();
  Future<Circle> getCircle(String circleId);
  Future<void> joinCircle(String circleId, String userId);
  Future<UbuntuUser> getUser(String userId);
  Future<String?> processPayment(String circleId, String userId, double amount, {String currency = "NGN"});
  Future<double> getExchangeRate();
  Future<UbuntuUser> getTrustPrediction(String userId);
  Future<void> createCircle({
    required String name,
    required double amount,
    required String frequency,
    required int maxMembers,
    required String creatorId,
    bool allowXb = false,
  });
  Future<void> processPayout(String circleId, String bankCode, String accountNo, String currency);
  Future<void> verifyKyc(String userId, String bvn);
  Future<List<Map<String, dynamic>>> getBanks();
  Future<Map<String, dynamic>> accountLookup(String bankCode, String accountNo);
  
  Future<String> login(String email, String password);
  Future<void> register(String email, String name, String password);
  Future<UbuntuUser> getMe();
}
