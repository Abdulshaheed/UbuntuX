import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/config/app_theme.dart';
import 'package:mobile/data/repositories/circle_repository_impl.dart';
import 'package:mobile/domain/entities/circle.dart';
import 'package:mobile/ui/pages/circle_details_page.dart';

class CircleListPage extends StatefulWidget {
  const CircleListPage({super.key});

  @override
  State<CircleListPage> createState() => _CircleListPageState();
}

class _CircleListPageState extends State<CircleListPage> {
  late final CircleRepositoryImpl repository;
  late Future<List<Circle>> circlesFuture;

  @override
  void initState() {
    super.initState();
    repository = CircleRepositoryImpl(Dio());
    circlesFuture = repository.getCircles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Circles'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Circle>>(
        future: circlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final circles = snapshot.data ?? [];
          
          if (circles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.savings_outlined, size: 64, color: UbuntuXTheme.silverGray.withOpacity(0.5)),
                   const SizedBox(height: 16),
                   Text(
                     'No Adashi to join yet',
                     style: Theme.of(context).textTheme.headlineSmall,
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: () {
                        Navigator.pop(context); // Go back to Home to create one
                     },
                     child: const Text('Go Back'),
                   ),
                ],
              ),
            );
          }

          return ListView.separated(

            padding: const EdgeInsets.all(24),
            itemCount: circles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final circle = circles[index];
              return _CircleCard(
                circle: circle,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CircleDetailsPage(circleId: circle.id),
                    ),
                  );
                  setState(() {
                    circlesFuture = repository.getCircles();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  final Circle circle;
  final VoidCallback onTap;

  const _CircleCard({required this.circle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UbuntuXTheme.deepNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UbuntuXTheme.slateBlue.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          circle.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${circle.frequency} contribution: ₦${circle.contributionAmount.toStringAsFixed(0)}'),
            Text('Members: ${circle.memberIds.length} / ${circle.maxMembers}'),
          ],
        ),
        trailing: circle.isFull
            ? const Text('FULL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            : Icon(Icons.chevron_right, color: UbuntuXTheme.accentCyan),
        onTap: circle.isFull ? null : onTap,
      ),
    );
  }
}
