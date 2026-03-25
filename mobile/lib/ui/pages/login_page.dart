import 'package:flutter/material.dart';
import 'package:mobile/core/config/app_theme.dart';
import 'package:mobile/ui/pages/home_page.dart';
import 'package:mobile/ui/pages/register_page.dart';
import 'package:mobile/data/repositories/circle_repository_impl.dart';
import 'package:dio/dio.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final CircleRepositoryImpl repository;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    repository = CircleRepositoryImpl(Dio());
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await repository.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UbuntuXTheme.deepNavy,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              UbuntuXTheme.deepNavy,
              UbuntuXTheme.slateBlue.withOpacity(0.2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded, 
                color: UbuntuXTheme.accentCyan, 
                size: 64,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to\nUbuntuX',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your communal wealth journey starts with a single step.',
                style: TextStyle(color: UbuntuXTheme.silverGray, fontSize: 16),
              ),
              const SizedBox(height: 48),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(color: UbuntuXTheme.silverGray),
                  prefixIcon: const Icon(Icons.email_outlined, color: UbuntuXTheme.accentCyan),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: UbuntuXTheme.slateBlue.withOpacity(0.5)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: UbuntuXTheme.accentCyan),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: UbuntuXTheme.silverGray),
                  prefixIcon: const Icon(Icons.lock_outline, color: UbuntuXTheme.accentCyan),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: UbuntuXTheme.slateBlue.withOpacity(0.5)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: UbuntuXTheme.accentCyan),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UbuntuXTheme.accentCyan,
                    foregroundColor: UbuntuXTheme.deepNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: UbuntuXTheme.accentCyan.withOpacity(0.4),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: UbuntuXTheme.deepNavy)
                    : const Text(
                        'Instant Login', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text('New to UbuntuX? Create Account', style: TextStyle(color: UbuntuXTheme.accentCyan)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Secured by Ubuntu Guardian AI',
                  style: TextStyle(color: UbuntuXTheme.silverGray.withOpacity(0.5), fontSize: 12),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
