import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';


class InterswitchPaymentPage extends StatefulWidget {
  final String circleId;
  final String userId;
  final double amount;
  final String currency;

  const InterswitchPaymentPage({
    super.key,
    required this.circleId,
    required this.userId,
    required this.amount,
    required this.currency,
  });

  @override
  State<InterswitchPaymentPage> createState() => _InterswitchPaymentPageState();
}

class _InterswitchPaymentPageState extends State<InterswitchPaymentPage> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() { isLoading = true; });
          },
          onPageFinished: (String url) {
            setState(() { isLoading = false; });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('ubuntux://payment-success')) {
              Navigator.pop(context, true); // Return success
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
      
    _loadPaymentUrl(); 
  }

  Future<void> _loadPaymentUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    final url = "http://10.0.2.2:8000/checkout/${widget.circleId}?user_id=${widget.userId}&amount=${widget.amount}&currency=${widget.currency}";
    
    await controller.loadRequest(
      Uri.parse(url),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        backgroundColor: Colors.transparent,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
