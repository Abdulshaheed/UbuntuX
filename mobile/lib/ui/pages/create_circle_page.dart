import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/config/app_theme.dart';
import 'package:mobile/data/repositories/circle_repository_impl.dart';

class CreateCirclePage extends StatefulWidget {
  const CreateCirclePage({super.key});

  @override
  State<CreateCirclePage> createState() => _CreateCirclePageState();
}

class _CreateCirclePageState extends State<CreateCirclePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _frequency = 'Monthly';
  int _maxMembers = 5;
  bool _allowXb = false;
  bool _isLoading = false;

  late final CircleRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    _repository = CircleRepositoryImpl(Dio());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _repository.createCircle(
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        frequency: _frequency,
        maxMembers: _maxMembers,
        creatorId: "u4", // Demo user
        allowXb: _allowXb,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adashi Circle Created!')),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        final detail = e.response?.data['detail'];
        String message = "Failed to create circle";
        if (detail is String) {
          message = detail;
        } else if (detail is List) {
          message = detail.map((e) => e.toString()).join('\n');
        }
        _showErrorDialog(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UbuntuXTheme.deepNavy,
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('AI Guardian Block', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start New Adashi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Circle Identity',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: UbuntuXTheme.accentCyan),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Circle Name',
                  hintText: 'e.g. Family Savings, Techies Pot',
                  prefixIcon: const Icon(Icons.group_work_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Financial Terms',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: UbuntuXTheme.accentCyan),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Contribution',
                        prefixText: '₦ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _frequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: ['Daily', 'Weekly', 'Monthly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => _frequency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Membership (Max: $_maxMembers)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: UbuntuXTheme.accentCyan),
              ),
              Slider(
                value: _maxMembers.toDouble(),
                min: 2,
                max: 20,
                divisions: 18,
                label: _maxMembers.toString(),
                activeColor: UbuntuXTheme.accentCyan,
                onChanged: (v) => setState(() => _maxMembers = v.toInt()),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: UbuntuXTheme.slateBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: UbuntuXTheme.accentCyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.public_rounded, color: UbuntuXTheme.accentCyan),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Allow Cross-Border Members', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Enables GBP payments for diaspora users.', style: TextStyle(fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _allowXb,
                      onChanged: (v) => setState(() => _allowXb = v),
                      activeColor: UbuntuXTheme.accentCyan,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UbuntuXTheme.accentCyan,
                    foregroundColor: UbuntuXTheme.deepNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Deploy Circle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
