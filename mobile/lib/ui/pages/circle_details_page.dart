import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/config/app_theme.dart';
import 'package:mobile/data/repositories/circle_repository_impl.dart';
import 'package:mobile/domain/entities/circle.dart';
import 'package:mobile/ui/pages/interswitch_payment_page.dart';

class CircleDetailsPage extends StatefulWidget {
  final String circleId;

  const CircleDetailsPage({super.key, required this.circleId});

  @override
  State<CircleDetailsPage> createState() => _CircleDetailsPageState();
}

class _CircleDetailsPageState extends State<CircleDetailsPage> {
  late final CircleRepositoryImpl repository;
  late Future<Circle> circleFuture;
  late Future<List<UbuntuUser>> membersFuture;
  bool isGBP = false;
  double exchangeRate = 1950.0;

  @override
  void initState() {
    super.initState();
    repository = CircleRepositoryImpl(Dio());
    _loadData();
  }

  void _loadData() {
    circleFuture = repository.getCircle(widget.circleId);
    membersFuture = circleFuture.then((circle) {
      return Future.wait(circle.memberIds.map((id) => repository.getUser(id)));
    });
    repository.getExchangeRate().then((rate) {
      if (mounted) {
        setState(() {
          exchangeRate = rate;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circle Details'),
        backgroundColor: Colors.transparent,
        actions: [
          Row(
            children: [
              Text('NGN', style: TextStyle(fontSize: 12, color: !isGBP ? UbuntuXTheme.accentCyan : Colors.white54)),
              Switch(
                value: isGBP,
                onChanged: (val) => setState(() => isGBP = val),
                activeColor: UbuntuXTheme.accentCyan,
              ),
              Text('GBP', style: TextStyle(fontSize: 12, color: isGBP ? UbuntuXTheme.accentCyan : Colors.white54)),
              const SizedBox(width: 16),
            ],
          ),
        ],
        elevation: 0,
      ),
      body: FutureBuilder<Circle>(
        future: circleFuture,
        builder: (context, circleSnapshot) {
          if (circleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (circleSnapshot.hasError) {
            return Center(child: Text('Error: ${circleSnapshot.error}'));
          }

          final circle = circleSnapshot.data!;

          return Column(
            children: [
              _buildHeader(circle),
              const Divider(height: 1, color: UbuntuXTheme.slateBlue),
              Expanded(
                child: _buildMemberList(),
              ),
              _buildJoinSection(circle),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Circle circle) {
    final displayContribution = isGBP ? circle.contributionAmount / exchangeRate : circle.contributionAmount;
    final displayPot = isGBP ? circle.totalPot / exchangeRate : circle.totalPot;
    final symbol = isGBP ? '£' : '₦';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(circle.name, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      '${circle.frequency} | $symbol${displayContribution.toStringAsFixed(isGBP ? 2 : 0)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Pot',
                    style: TextStyle(color: UbuntuXTheme.silverGray, fontSize: 12),
                  ),
                  Text(
                    '$symbol${displayPot.toStringAsFixed(isGBP ? 2 : 0)}',
                    style: TextStyle(
                      color: UbuntuXTheme.accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  if (circle.totalPot > 0)
                    TextButton.icon(
                      onPressed: () async {
                        try {
                           showDialog(
                             context: context,
                             barrierDismissible: false,
                             builder: (_) => const Center(child: CircularProgressIndicator()),
                           );
                           await repository.processPayout(circle.id, "u4", "058", "0123456789", isGBP ? "GBP" : "NGN");
                           Navigator.pop(context);
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Payout Successful! Funds transferred.'), backgroundColor: Colors.green),
                           );
                           setState(() { _loadData(); });
                        } catch (e) {
                           Navigator.pop(context);
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Payout Failed: $e'), backgroundColor: Colors.red),
                           );
                        }
                      },
                      icon: const Icon(Icons.account_balance_wallet, size: 16, color: Colors.greenAccent),
                      label: const Text('Disburse Pot', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.group_rounded, color: UbuntuXTheme.silverGray, size: 20),
              const SizedBox(width: 8),
              Text('${circle.memberIds.length} / ${circle.maxMembers} Members'),
              if (isGBP) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Rate: 1 GBP = ₦${exchangeRate.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList() {
    return FutureBuilder<List<UbuntuUser>>(
      future: membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return const Center(child: Text('No members yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: UbuntuXTheme.slateBlue,
                child: Text(member.name[0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(member.name),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: UbuntuXTheme.accentCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: UbuntuXTheme.accentCyan.withOpacity(0.5)),
                ),
                child: Text(
                  'Trust: ${member.trustScore}',
                  style: const TextStyle(color: UbuntuXTheme.accentCyan, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildJoinSection(Circle circle) {
    bool isAlreadyMember = circle.memberIds.contains("u4"); // Hardcoded user for demo
    final currency = isGBP ? "GBP" : "NGN";
    final payAmount = isGBP ? circle.contributionAmount / exchangeRate : circle.contributionAmount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: UbuntuXTheme.deepNavy,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: SafeArea(
        child: isAlreadyMember
            ? ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final success = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InterswitchPaymentPage(
                          circleId: circle.id,
                          userId: "u4",
                          amount: payAmount,
                          currency: currency,
                        ),
                      ),
                    );

                    if (success == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment Successful!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 4),
                        ),
                      );
                      setState(() {
                        _loadData();
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment Failed: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: Icon(isGBP ? Icons.public : Icons.payment_rounded),
                label: Text(isGBP ? 'Pay via Cross-Border (GBP)' : 'Pay Monthly Share (NGN)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: isGBP ? Colors.amber : UbuntuXTheme.accentCyan,
                  foregroundColor: UbuntuXTheme.darkBlue,
                ),
              )
            : ElevatedButton(
                onPressed: circle.isFull
                    ? null
                    : () async {
                        try {
                          await repository.joinCircle(circle.id, "u4");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Successfully joined circle!')),
                          );
                          setState(() {
                            _loadData();
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to join: $e')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Join This Circle'),
              ),
      ),
    );
  }
}
