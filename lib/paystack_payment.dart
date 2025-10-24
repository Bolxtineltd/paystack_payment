import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'paystack_response.dart';

class PaystackPayment {
  const PaystackPayment();

  Future<void> checkout({
    required BuildContext context,
    required String accessCode,
    required ValueChanged<PaystackResponse> onSuccess,
    required ValueChanged<PaystackResponse> onError,
    required ValueChanged<PaystackResponse> onCancel,
    PaystackCheckoutOptions options = const PaystackCheckoutOptions(),
  }) async {
    final initialUrl =
        options.authorizationUrl ?? 'https://checkout.paystack.com/$accessCode';

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => _PaystackWebView(
              initialUrl: initialUrl,
              options: options,
              onSuccess: onSuccess,
              onError: onError,
              onCancel: onCancel,
            ),
      ),
    );
  }
}

class PaystackCheckoutOptions {
  final String? authorizationUrl;
  final String? successUrl; // <-- merchant callback for success
  final String? cancelUrl; // <-- merchant callback for cancel
  final String title;
  final Color appBarBackgroundColor;
  final Color appBarForegroundColor;

  const PaystackCheckoutOptions({
    this.authorizationUrl,
    this.successUrl,
    this.cancelUrl,
    this.title = 'Pay with Paystack',
    this.appBarBackgroundColor = const Color(0xFF673AB7),
    this.appBarForegroundColor = Colors.white,
  });
}

class _PaystackWebView extends StatefulWidget {
  final String initialUrl;
  final PaystackCheckoutOptions options;
  final ValueChanged<PaystackResponse> onSuccess;
  final ValueChanged<PaystackResponse> onError;
  final ValueChanged<PaystackResponse> onCancel;

  const _PaystackWebView({
    required this.initialUrl,
    required this.options,
    required this.onSuccess,
    required this.onError,
    required this.onCancel,
  });

  @override
  State<_PaystackWebView> createState() => _PaystackWebViewState();
}

class _PaystackWebViewState extends State<_PaystackWebView> {
  late final WebViewController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: _handleNavigationRequest,
              onPageFinished: _handlePageFinished,
              onWebResourceError: _handleWebResourceError,
            ),
          )
          ..loadRequest(Uri.parse(widget.initialUrl));
  }

  // -------------------------------------------------------------------------
  //  Navigation handling
  // -------------------------------------------------------------------------
  Future<NavigationDecision> _handleNavigationRequest(
    NavigationRequest request,
  ) async {
    if (!request.isMainFrame) return NavigationDecision.navigate;

    final uri = _tryParseUri(request.url);
    if (uri == null) return NavigationDecision.navigate;

    // External schemes (mailto:, tel:, …) → open externally
    if (!_isWebScheme(uri.scheme)) {
      await _launchExternal(uri);
      return NavigationDecision.prevent;
    }

    // Terminal-state detection – if true we **prevent** further navigation
    final terminal = _checkTerminal(uri);
    if (terminal) return NavigationDecision.prevent;

    return NavigationDecision.navigate;
  }

  void _handlePageFinished(String url) {
    final uri = _tryParseUri(url);
    if (uri != null) _checkTerminal(uri);
  }

  void _handleWebResourceError(WebResourceError error) {
    log('WebView error: ${error.errorCode} - ${error.description}');
    if (error.isForMainFrame == true) {
      widget.onError(
        PaystackResponse.error('WebView error: ${error.description}'),
      );
    }
  }

  Future<void> _launchExternal(Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      widget.onError(
        PaystackResponse.error(
          'Unable to open external application needed to complete payment.',
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  //  Terminal-state detection
  // -------------------------------------------------------------------------
  bool _checkTerminal(Uri uri) {
    if (_completed) return true;

    // 1. Explicit merchant URLs supplied by the caller
    if (widget.options.successUrl != null &&
        _urlStartsWith(uri, widget.options.successUrl!)) {
      final ref = _extractReference(uri) ?? 'unknown';
      _completeWith(widget.onSuccess, PaystackResponse.success(ref));
      return true;
    }

    if (widget.options.cancelUrl != null &&
        _urlStartsWith(uri, widget.options.cancelUrl!)) {
      _completeWith(widget.onCancel, PaystackResponse.cancelled());
      return true;
    }

    // 2. Paystack-hosted success / cancel pages
    if (_isPaystackHost(uri.host)) {
      // Success
      if (_isSuccessUri(uri)) {
        final ref = _extractReference(uri) ?? 'unknown';
        _completeWith(widget.onSuccess, PaystackResponse.success(ref));
        return true;
      }

      // Cancel / failure
      if (_isCancelUri(uri)) {
        _completeWith(widget.onCancel, PaystackResponse.cancelled());
        return true;
      }

      // No explicit status → still on Paystack domain → keep loading
      return false;
    }

    // 3. ANY navigation **away** from Paystack is considered a terminal callback.
    //    Paystack redirects to the merchant URL *without* query parameters.
    final ref = _extractReference(uri) ?? 'unknown';
    _completeWith(widget.onSuccess, PaystackResponse.success(ref));
    return true;
  }

  void _completeWith(
    ValueChanged<PaystackResponse> callback,
    PaystackResponse response,
  ) {
    if (_completed || !mounted) return;
    _completed = true;
    callback(response);
    Navigator.of(context).pop();
  }

  // -------------------------------------------------------------------------
  //  UI
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _completeWith(widget.onCancel, PaystackResponse.cancelled());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.options.appBarBackgroundColor,
          foregroundColor: widget.options.appBarForegroundColor,
          title: Text(
            widget.options.title,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white),
          ),
          titleTextStyle: TextStyle(),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed:
                () => _completeWith(
                  widget.onCancel,
                  PaystackResponse.cancelled(),
                ),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  Helpers
  // -------------------------------------------------------------------------
  bool _isWebScheme(String? scheme) =>
      scheme != null && (scheme == 'http' || scheme == 'https');

  Uri? _tryParseUri(String value) {
    try {
      return Uri.parse(value);
    } catch (_) {
      return null;
    }
  }

  bool _urlStartsWith(Uri uri, String pattern) {
    final lower = pattern.toLowerCase().trim();
    return uri.toString().toLowerCase().startsWith(lower);
  }

  bool _isPaystackHost(String host) {
    final h = host.toLowerCase();
    return h.endsWith('paystack.co') ||
        h.endsWith('paystack.com') ||
        h.contains('.paystack.');
  }

  String? _extractReference(Uri uri) {
    final p = uri.queryParameters;
    return p['reference'] ?? p['trxref'];
  }

  bool _isSuccessUri(Uri uri) {
    final status = uri.queryParameters['status']?.toLowerCase();
    final ref = _extractReference(uri);
    final path = uri.path.toLowerCase();

    // reference present → Paystack success page
    if (ref != null && uri.queryParameters.containsKey('reference'))
      return true;

    // close-frame handling
    if (ref != null && path.contains('close')) {
      return status == null || status == 'success';
    }

    if (ref != null && (status == 'success' || status == 'completed')) {
      return true;
    }

    if (ref != null &&
        uri.queryParameters['message']?.toLowerCase() == 'approved') {
      return true;
    }

    return false;
  }

  bool _isCancelUri(Uri uri) {
    inspect(uri);
    final status = uri.queryParameters['status']?.toLowerCase();
    final path = uri.path.toLowerCase();

    if (_isPaystackHost(uri.host)) {
      if (status == 'cancelled' || status == 'failed') return true;
      if (path.contains('cancel')) return true;
    }

    if (status == 'cancelled' || status == 'failed' || status == 'abandoned') {
      return true;
    }

    final msg = uri.queryParameters['message']?.toLowerCase();
    if (msg == 'cancelled' || msg == 'failed') return true;

    return false;
  }
}
