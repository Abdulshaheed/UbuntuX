import 'package:mobile/domain/entities/circle.dart';

class CircleModel extends Circle {
  CircleModel({
    required super.id,
    required super.name,
    required super.contributionAmount,
    required super.maxMembers,
    required super.frequency,
    required super.memberIds,
    required super.totalPot,
    required super.isCrossBorderAllowed,
  });

  factory CircleModel.fromJson(Map<String, dynamic> json) {
    return CircleModel(
      id: json['id'],
      name: json['name'],
      contributionAmount: (json['contribution_amount'] as num).toDouble(),
      maxMembers: json['max_members'],
      frequency: json['frequency'],
      memberIds: List<String>.from(json['member_ids'] ?? []),
      totalPot: (json['total_pot'] as num?)?.toDouble() ?? 0.0,
      isCrossBorderAllowed: json['is_cross_border_allowed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contribution_amount': contributionAmount,
      'max_members': maxMembers,
      'frequency': frequency,
      'member_ids': memberIds,
      'total_pot': totalPot,
      'is_cross_border_allowed': isCrossBorderAllowed,
    };
  }
}

class UserModel extends UbuntuUser {
  UserModel({
    required super.id,
    required super.name,
    required super.trustScore,
    required super.onTimePercentage,
    required super.riskLevel,
    required super.isKycVerified,
    required super.trustAnalysisFactors,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? "",
      name: json['name'] ?? "User",
      trustScore: json['trust_score'] ?? 0,
      onTimePercentage: (json['on_time_percentage'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] ?? "Medium",
      isKycVerified: json['is_kyc_verified'] ?? false,
      trustAnalysisFactors: json['analysis_factors'] != null 
          ? Map<String, String>.from(json['analysis_factors'])
          : {},
    );
  }
}
