import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebPortalViewScreen extends StatefulWidget {
  final String initialUrl;
  final String title;

  const WebPortalViewScreen({
    super.key,
    this.initialUrl = 'http://localhost:3000/',
    this.title = 'E-Reportyan Web Portal',
  });

  @override
  State<WebPortalViewScreen> createState() => _WebPortalViewScreenState();
}

class _WebPortalViewScreenState extends State<WebPortalViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView Error: ${error.description}');
              // If local server fails, fall back to asset loading or retry
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.initialUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0038A8), // GOV.PH Royal Blue
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_controller != null) {
                _controller!.reload();
              }
            },
            tooltip: 'Refresh Web Portal',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!kIsWeb && _controller != null)
            WebViewWidget(controller: _controller!)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.web, size: 64, color: Color(0xFF0038A8)),
                    const SizedBox(height: 16),
                    Text(
                      'E-Reportyan Public Web Portal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Running on Web Browser Mode.\nAccess the live web design at http://localhost:3000/',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading && !kIsWeb)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0038A8)),
              ),
            ),
        ],
      ),
    );
  }
}
