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
                return TrustScoreCard(
                  score: user.trustScore, 
                  riskLevel: user.riskLevel,
                  factors: user.trustAnalysisFactors,
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
