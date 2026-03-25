import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mobile/ui/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/config/app_theme.dart';
import 'package:mobile/ui/widgets/trust_score_card.dart';
import 'package:mobile/ui/widgets/home_action_button.dart';
import 'package:mobile/ui/pages/circle_list_page.dart';
import 'package:mobile/ui/pages/create_circle_page.dart';
import 'package:mobile/ui/pages/circle_details_page.dart';
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
  late Future<List<Circle>> activeCirclesFuture;
  String _userPhone = "Ubuntu";

  @override
  void initState() {
    super.initState();
    repository = CircleRepositoryImpl(Dio());
    _refreshData();
  }

  void _refreshData() {
    userFuture = _loadInitialData();
    activeCirclesFuture = _loadActiveCircles();
  }

  Future<UbuntuUser> _loadInitialData() async {
    try {
      final user = await repository.getMe();
      if (mounted) {
        setState(() {
          _userPhone = user.name;
        });
      }
      return user;
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      rethrow;
    }
  }

  Future<List<Circle>> _loadActiveCircles() async {
    try {
      final user = await repository.getMe();
      final allCircles = await repository.getCircles();
      return allCircles.where((c) => c.memberIds.contains(user.id)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    // Clear repository headers
    repository.dio.options.headers.remove('Authorization');

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
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
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _refreshData();
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const AlwaysScrollableScrollPhysics(),
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
                    MaterialPageRoute(
                      builder: (context) => const CircleListPage(),
                    ),
                  ).then((_) {
                    setState(() {
                      _refreshData();
                    });
                  });
                },
              ),
              const SizedBox(height: 16),
              HomeActionButton(
                label: 'Interswitch Cross-Border',
                icon: Icons.public_rounded,
                onPressed: () {},
                color: UbuntuXTheme.slateBlue,
              ),
              const SizedBox(height: 40),
              _buildSectionHeader(context, 'My Active Circles'),
              const SizedBox(height: 16),

              FutureBuilder<List<Circle>>(
                future: activeCirclesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final circles = snapshot.data ?? [];
                  if (circles.isEmpty) {
                    return _buildEmptyCirclePlaceholder(context);
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: circles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final circle = circles[index];
                      return _buildActiveCircleCard(context, circle);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCircleCard(BuildContext context, Circle circle) {
    return Container(
      decoration: BoxDecoration(
        color: UbuntuXTheme.deepNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UbuntuXTheme.slateBlue.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CircleDetailsPage(circleId: circle.id),
            ),
          ).then((_) => setState(() => _refreshData()));
        },
        title: Text(
          circle.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Pot: ₦${circle.totalPot.toStringAsFixed(0)}'),
        trailing: const Icon(
          Icons.chevron_right,
          color: UbuntuXTheme.accentCyan,
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
        TextButton(onPressed: () {}, child: const Text('See All')),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  'Verify your identity with Interswitch to gain +15 trust points.',
                  style: TextStyle(
                    color: Colors.amber.withOpacity(0.8),
                    fontSize: 12,
                  ),
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (bvnController.text.length != 11) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid 11-digit BVN'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext); // Close input dialog

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final user = await repository.getMe();
                await repository.verifyKyc(user.id, bvnController.text);

                if (mounted) {
                  Navigator.of(context).pop(); // Close loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Identity Verified Successfully! Trust Score Boosted.',
                      ),
                    ),
                  );
                  setState(() {
                    _refreshData();
                  });
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification Failed: $e')),
                  );
                }
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
        border: Border.all(color: UbuntuXTheme.slateBlue.withOpacity(0.3)),
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
                MaterialPageRoute(
                  builder: (context) => const CreateCirclePage(),
                ),
              ).then((result) {
                if (result == true) {
                  setState(() {
                    _refreshData();
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
