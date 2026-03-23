import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/config/app_theme.dart';
import 'package:mobile/ui/widgets/trust_score_card.dart';
import 'package:mobile/ui/widgets/home_action_button.dart';
import 'package:mobile/ui/pages/circle_list_page.dart';
import 'package:mobile/ui/pages/create_circle_page.dart';
import 'package:mobile/data/repositories/circle_repository_impl.dart';
import 'package:mobile/domain/entities/circle.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CircleRepositoryImpl repository;
  late Future<UbuntuUser> userFuture;
  String _userPhone = "Ubuntu";

  @override
  void initState() {
    super.initState();
    repository = CircleRepositoryImpl(Dio());
    userFuture = repository.getTrustPrediction("u4"); // Fetch for demo user
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPhone = prefs.getString('user_phone') ?? "Ubuntu";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'UbuntuX',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $_userPhone!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your communal wealth journey starts here.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            
            FutureBuilder<UbuntuUser>(
              future: userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const TrustScorePlaceholder();
                }
                if (snapshot.hasError) {
                  return const TrustScoreCard(score: 0, riskLevel: "N/A");
                }
                final user = snapshot.data!;
                return Column(
                  children: [
                    TrustScoreCard(
                      score: user.trustScore, 
                      riskLevel: user.riskLevel,
                      isKycVerified: user.isKycVerified,
                      factors: user.trustAnalysisFactors,
                    ),
                    if (!user.isKycVerified) ...[
                      const SizedBox(height: 16),
                      _buildKycBooster(context),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 40),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 16),
            HomeActionButton(
              label: 'Join Savings Circle',
              icon: Icons.group_add_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CircleListPage()),
                ).then((_) {
                  setState(() {
                    userFuture = repository.getTrustPrediction("u4");
                  });
                });
              },
            ),
            const SizedBox(height: 16),
            HomeActionButton(
              label: 'Cross-Border Transfer',
              icon: Icons.send_rounded,
              onPressed: () {},
              color: UbuntuXTheme.slateBlue,
            ),
            const SizedBox(height: 40),
            _buildSectionHeader(context, 'Active Circles'),
            const SizedBox(height: 16),
            _buildEmptyCirclePlaceholder(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 18),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('See All'),
        ),
      ],
    );
  }


  Widget _buildKycBooster(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score Booster Available',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                Text(
                  'Verify your identity with Interswitch to gain +15 trust points.',
                  style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showKycDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(64, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Verify', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showKycDialog(BuildContext context) {
    final TextEditingController bvnController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UbuntuXTheme.deepNavy,
        title: const Text('Identity Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your 11-digit BVN to verify your identity via Interswitch Identity API.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bvnController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bank Verification Number (BVN)',
                hintText: '12345678901',
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (bvnController.text.length != 11) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 11-digit BVN')),
                );
                return;
              }
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                await repository.verifyKyc("u4", bvnController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Identity Verified Successfully! Trust Score Boosted.')),
                );
                setState(() {
                  userFuture = repository.getTrustPrediction("u4");
                });
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Verification Failed: $e')),
                );
              }
            },
            child: const Text('Verify Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCirclePlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: UbuntuXTheme.deepNavy.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: UbuntuXTheme.slateBlue.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 48,
            color: UbuntuXTheme.silverGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No active circles yet',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateCirclePage()),
              ).then((result) {
                if (result == true) {
                  setState(() {
                    userFuture = repository.getTrustPrediction("u4");
                  });
                }
              });
            },
            child: const Text('Start your first Adashi'),
          ),
        ],
      ),
    );
  }
}

class TrustScorePlaceholder extends StatelessWidget {
  const TrustScorePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: UbuntuXTheme.deepNavy.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
