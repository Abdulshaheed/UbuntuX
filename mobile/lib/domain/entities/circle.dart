class Circle {
  final String id;
  final String name;
  final double contributionAmount;
  final int maxMembers;
  final String frequency;
  final List<String> memberIds;
  final double totalPot;
  final String creatorId;
  final bool isCrossBorderAllowed;

  Circle({
    required this.id,
    required this.name,
    required this.contributionAmount,
    required this.maxMembers,
    required this.frequency,
    required this.memberIds,
    required this.totalPot,
    required this.creatorId,
    this.isCrossBorderAllowed = false,
  });

  bool get isFull => memberIds.length >= maxMembers;
}

class UbuntuUser {
  final String id;
  final String name;
  final int trustScore;
  final double onTimePercentage;
  final String riskLevel;
  final bool isKycVerified;
  final Map<String, String> trustAnalysisFactors;

  UbuntuUser({
    required this.id,
    required this.name,
    required this.trustScore,
    required this.onTimePercentage,
    this.riskLevel = "Medium",
    this.isKycVerified = false,
    this.trustAnalysisFactors = const {},
  });
}
