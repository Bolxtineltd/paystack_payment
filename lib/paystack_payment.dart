import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'paystack_response.dart';

class PaystackPayment {
  final String secretKey;

  PaystackPayment({required this.secretKey});

  Future<void> pay({
    required BuildContext context,
    required String email,
    required double amount,
    required String currency,
    String? reference,
    String? callbackUrl,
    List<String>? channels,
    Map<String, dynamic>? metadata,
    required Function(PaystackResponse) onSuccess,
    required Function(PaystackResponse) onError,
    required Function(PaystackResponse) onCancel,
  }) async {
    try {
      final response = await _initializeTransaction(
        email: email,
        amount: amount,
        currency: currency,
        reference: reference,
        callbackUrl: callbackUrl,
        channels: channels,
        metadata: metadata,
      );

      if (response['status'] == true) {
        final authorizationUrl = response['data']['authorization_url'];
        _showPaymentWebView(
          context: context,
          url: authorizationUrl,
          onSuccess: onSuccess,
          onError: onError,
          onCancel: onCancel,
        );
      } else {
        onError(
          PaystackResponse.error(
            'Failed to initialize transaction: ${response['message']}',
          ),
        );
      }
    } catch (e) {
      onError(PaystackResponse.error('Error: $e'));
    }
  }

  Future<Map<String, dynamic>> _initializeTransaction({
    required String email,
    required double amount,
    required String currency,
    String? reference,
    String? callbackUrl,
    List<String>? channels,
    Map<String, dynamic>? metadata,
  }) async {
    final url = Uri.parse('https://api.paystack.co/transaction/initialize');
    final headers = {
      'Authorization': 'Bearer $secretKey',
      'Content-Type': 'application/json',
    };

    final mergedMetadata = _mergeMetadata(metadata);

    final body = jsonEncode({
      'email': email,
      'amount': (amount * 100).toInt(),
      'currency': currency,
      if (reference != null) 'reference': reference,
      if (callbackUrl != null) 'callback_url': callbackUrl,
      if (channels != null) 'channels': channels,
      'metadata': mergedMetadata,
    });

    log('Sending to Paystack: $body');
    final response = await http.post(url, headers: headers, body: body);
    log('Paystack response: ${response.body}');
    return jsonDecode(response.body);
  }

  Map<String, dynamic> _mergeMetadata(Map<String, dynamic>? userMetadata) {
    final defaultMetadata = {
      'cancel_action': 'https://www.bolxtine.com/?status=cancelled',
    };
    if (userMetadata == null) {
      return defaultMetadata;
    }
    return {...defaultMetadata, ...userMetadata};
  }

  void _showPaymentWebView({
    required BuildContext context,
    required String url,
    required Function(PaystackResponse) onSuccess,
    required Function(PaystackResponse) onError,
    required Function(PaystackResponse) onCancel,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _PaystackWebView(
              url: url,
              onSuccess: onSuccess,
              onError: onError,
              onCancel: onCancel,
            ),
      ),
    );
  }
}

class _PaystackWebView extends StatefulWidget {
  final String url;
  final Function(PaystackResponse) onSuccess;
  final Function(PaystackResponse) onError;
  final Function(PaystackResponse) onCancel;

  const _PaystackWebView({
    required this.url,
    required this.onSuccess,
    required this.onError,
    required this.onCancel,
  });

  @override
  _PaystackWebViewState createState() => _PaystackWebViewState();
}

class _PaystackWebViewState extends State<_PaystackWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                // log('Page started: $url');
              },
              onPageFinished: (url) async {
                // log('Page finished: $url');
                final uri = Uri.parse(url);

                if (uri.queryParameters.containsKey('reference')) {
                  final reference =
                      uri.queryParameters['reference'] ?? 'unknown';
                  // log('Success detected with reference: $reference');
                  widget.onSuccess(PaystackResponse.success(reference));
                  Navigator.pop(context);
                } else if (url.contains('cancel') ||
                    url.contains('status=cancelled')) {
                  // log('Cancel detected in URL');
                  widget.onCancel(PaystackResponse.cancelled());
                  Navigator.pop(context);
                } else {
                  // log('No success or cancel condition met for URL: $url');
                }

                await _injectCancelListener();
              },
              onNavigationRequest: (request) {
                log('Navigation request: ${request.url}');
                final uri = Uri.parse(request.url);

                if (uri.queryParameters.containsKey('reference')) {
                  final reference =
                      uri.queryParameters['reference'] ?? 'unknown';
                  log(
                    'Success detected in navigation with reference: $reference',
                  );
                  widget.onSuccess(PaystackResponse.success(reference));
                  Navigator.pop(context);
                  return NavigationDecision.prevent;
                } else if (request.url.contains('cancel') ||
                    request.url.contains('status=cancelled')) {
                  log('Cancel detected in navigation');
                  widget.onCancel(PaystackResponse.cancelled());
                  Navigator.pop(context);
                  return NavigationDecision.prevent;
                }

                return NavigationDecision.navigate;
              },
              onWebResourceError: (error) {
                log('WebView error: ${error.description}');
                widget.onError(
                  PaystackResponse.error('WebView error: ${error.description}'),
                );
                Navigator.pop(context);
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _injectCancelListener() async {
    const jsCode = '''
      (function() {
        var cancelButton = document.querySelector('button[data-testid="cancel-payment"]') || 
                          document.querySelector('button.cancel-button') || 
                          document.querySelector('a[href*="cancel"]');
        if (cancelButton) {
          cancelButton.addEventListener('click', function() {
            window.flutter_inappwebview.callHandler('cancelPayment');
          });
        }
      })();
    ''';
    await _controller.runJavaScript(jsCode);

    _controller.addJavaScriptChannel(
      'cancelPayment',
      onMessageReceived: (args) {
        log('Cancel triggered via JavaScript');
        widget.onCancel(PaystackResponse.cancelled());
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Pay with Paystack',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            log('Manual close triggered');
            widget.onCancel(PaystackResponse.cancelled());
            Navigator.pop(context);
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
