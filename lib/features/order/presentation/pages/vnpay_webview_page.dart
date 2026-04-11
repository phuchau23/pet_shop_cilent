import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';

class VnPayWebViewPage extends StatefulWidget {
  final String paymentUrl;

  const VnPayWebViewPage({super.key, required this.paymentUrl});

  @override
  State<VnPayWebViewPage> createState() => _VnPayWebViewPageState();
}

class _VnPayWebViewPageState extends State<VnPayWebViewPage> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onNavigationRequest: (request) {
              if (_isVnPayReturnUrl(request.url)) {
                Navigator.of(context).pop(true);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );

      _controller = controller;
      await controller.loadRequest(Uri.parse(widget.paymentUrl));
      if (mounted) setState(() {});
    } catch (_) {
      // Fallback an toàn khi plugin chưa attach (thường gặp nếu chỉ hot reload sau khi thêm plugin)
      final opened = await launchUrl(
        Uri.parse(widget.paymentUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WebView chưa sẵn sàng. Đã mở trình duyệt ngoài. Hãy tắt app chạy lại để dùng WebView trong app.',
          ),
        ),
      );
      Navigator.of(context).pop(opened);
    }
  }

  bool _isVnPayReturnUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/api/payments/vnpay/return');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!)
          else
            const SizedBox.shrink(),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
