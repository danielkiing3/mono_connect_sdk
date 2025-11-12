import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mono_connect_sdk/src/core/constants/mono_connect_config_constant.dart';
import 'package:mono_connect_sdk/src/core/log/default_mono_logger.dart';
import 'package:mono_connect_sdk/src/core/log/mono_logger.dart';
import 'package:mono_connect_sdk/src/enums/mono_event.dart';
import 'package:mono_connect_sdk/src/enums/mono_event_type.dart';
import 'package:mono_connect_sdk/src/core/extensions/map.dart';
import 'package:mono_connect_sdk/src/models/models.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

typedef MonoOnEvent = void Function(MonoEvent event, MonoEventData? data);

/// Callbacks for Mono Connect events
@immutable
class MonoConnectCallbacks {
  /// Called when account linking succeeds
  final ValueChanged<String>? onSuccess;

  /// Called when user closes the widget
  final ValueChanged<String?>? onClosed;

  /// Called when the widget loads
  final VoidCallback? onLoad;

  /// Called for custom events
  final MonoOnEvent? onEvent;

  const MonoConnectCallbacks({
    this.onSuccess,
    this.onClosed,
    this.onLoad,
    this.onEvent,
  });
}

class MonoConnectView extends StatefulWidget {
  final MonoConnectConfig config;
  final MonoConnectCallbacks? callbacks;

  /// Custom error widget builder that receives a retry callback
  final Widget Function(VoidCallback onRetry)? errorWidgetBuilder;

  /// Custom loading widget to display while page loads
  final Widget? loadingWidget;

  /// Custom logger for debugging and monitoring
  final MonoLogger? logger;

  const MonoConnectView({
    super.key,
    required this.config,
    this.callbacks,
    this.errorWidgetBuilder,
    this.loadingWidget,
    this.logger,
  });

  /// Convenience constructor maintaining backwards compatibility
  factory MonoConnectView.legacy({
    required String apiKey,
    required MonoCustomer customer,
    String reAuthCode = '',
    String? reference,
    String scope = 'auth',
    String? paymentUrl,
    ConnectInstitution? selectedInstitution,
    ValueChanged<String>? onSuccess,
    ValueChanged<String?>? onClosed,
    VoidCallback? onLoad,
    MonoOnEvent? onEvent,
    Widget Function(VoidCallback onRetry)? errorWidgetBuilder,
    Widget? loadingWidget,
    MonoLogger? logger,
  }) {
    return MonoConnectView(
      config: MonoConnectConfig(
        apiKey: apiKey,
        customer: customer,
        reAuthCode: reAuthCode,
        reference: reference,
        scope: scope,
        paymentUrl: paymentUrl,
        selectedInstitution: selectedInstitution,
      ),
      callbacks: MonoConnectCallbacks(
        onSuccess: onSuccess,
        onClosed: onClosed,
        onLoad: onLoad,
        onEvent: onEvent,
      ),
      errorWidgetBuilder: errorWidgetBuilder,
      loadingWidget: loadingWidget,
      logger: logger,
    );
  }

  @override
  MonoConnectViewState createState() => MonoConnectViewState();
}

class MonoConnectViewState extends State<MonoConnectView> {
  late WebViewController _webViewController;
  late final ValueNotifier<bool> _isLoading = ValueNotifier(true);
  late final ValueNotifier<bool> _hasError = ValueNotifier(false);
  late final MonoLogger _logger;

  bool _hasClosed = false;

  final UniqueKey _key = UniqueKey();

  @override
  void initState() {
    super.initState();

    _logger = widget.logger ?? DefaultMonoLogger();
    _logger.info('Initializing Mono Connect WebView');
    _initializeWebView();
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _hasError.dispose();
    super.dispose();
  }

  /// Initialize WebView with platform-specific parameters
  void _initializeWebView() {
    final params = _createPlatformParams();

    _webViewController = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) => request.grant(),
    );

    _configureWebView();
    _requestPermissionsAndLoad();
  }

  /// Create platform-specific WebView parameters
  PlatformWebViewControllerCreationParams _createPlatformParams() {
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      return WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    }

    // Default params
    return const PlatformWebViewControllerCreationParams();
  }

  /// Configure WebView settings and delegates
  void _configureWebView() {
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        MonoConnectConfigConstant.jsChannelName,
        onMessageReceived: _handleJavaScriptMessage,
      )
      ..setNavigationDelegate(_createNavigationDelegate());
  }

  /// Create navigation delegate with lifecycle callbacks
  NavigationDelegate _createNavigationDelegate() {
    return NavigationDelegate(
      onPageStarted: (_) {
        _isLoading.value = true;
        _hasError.value = false;
      },
      onPageFinished: (_) {
        _isLoading.value = false;

        if (Theme.of(context).brightness == Brightness.dark && mounted) {
          _webViewController.runJavaScript(
            MonoConnectConfigConstant.darkModeScript,
          );
        }
      },
      onWebResourceError: (error) {
        _logger.error('WebView resource error', error.description);
        _isLoading.value = false;
        _hasError.value = true;
      },
      onNavigationRequest: (_) => NavigationDecision.navigate,
    );
  }

  /// Request camera permissions and load WebView
  Future<void> _requestPermissionsAndLoad() async {
    if (!kIsWeb) {
      await _requestCameraPermission();
    }
    await _loadMonoConnect();
  }

  /// Request camera permission for ID verification
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  /// Load Mono Connect URL
  Future<void> _loadMonoConnect() async {
    try {
      final uri = widget.config.buildConnectUri();
      _logger.info('Loading Mono Connect', {'uri': uri.toString()});
      await _webViewController.loadRequest(uri);
    } catch (e, stackTrace) {
      _logger.error('Failed to load Mono Connect', e, stackTrace);
      _hasError.value = true;
    }
  }

  /// Handle messages from JavaScript channel
  void _handleJavaScriptMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;

      _logger.debug('Received Mono event', {
        'type': data['type'],
        'raw': message.message,
      });

      _processMonoEvent(data);
    } catch (e, stackTrace) {
      _logger.error('Error parsing Mono message', e, stackTrace);
    }
  }

  /// Process event from Mono Connect
  void _processMonoEvent(Map<String, dynamic> eventData) {
    final eventType = eventData['type'] as String?;
    if (eventType == null) return;

    final MonoEventType type = MonoEventType.fromString(eventType);

    switch (type) {
      case MonoEventType.accountLinked:
        _handleAccountLinked(eventData);
        break;

      case MonoEventType.widgetClosed:
      case MonoEventType.modalClosed:
        _handleWidgetClosed(eventData);
        break;

      case MonoEventType.widgetOpened:
      case MonoEventType.modalLoad:
        _handleWidgetOpened();
        break;

      case MonoEventType.unknown:
        _handleCustomEvent(eventType, eventData);
        break;
    }
  }

  /// Handle successful account linking
  void _handleAccountLinked(Map<String, dynamic> eventData) {
    final code = eventData['response']?['code'] as String?;
    if (code == null) {
      _logger.error('Account linked event missing code');
      return;
    }

    _logger.info('Account successfully linked', {'code': code});
    widget.callbacks?.onSuccess?.call(code);
    _closeWebView(code);
  }

  /// Handle widget close event
  void _handleWidgetClosed(Map<String, dynamic> eventData) {
    String? code;
    try {
      code = eventData['data']?['code'] as String?;
    } catch (e, stackTrace) {
      _logger.error('Error extracting close code', e, stackTrace);
    }

    _logger.info('Widget closed', {'code': code});

    if (code != null) {
      widget.callbacks?.onSuccess?.call(code);
    }

    widget.callbacks?.onClosed?.call(code);
    _closeWebView(code);
  }

  /// Handle widget opened event
  void _handleWidgetOpened() {
    if (!mounted) return;
    _logger.info('Widget opened successfully');
    widget.callbacks?.onLoad?.call();
  }

  /// Handle custom events
  void _handleCustomEvent(String eventType, Map<String, dynamic> eventData) {
    _logger.debug('Custom event received', {
      'type': eventType,
      'data': eventData['data'],
    });

    final MonoEvent event = MonoEventExtension.fromString(
      eventType.split('.').last,
    );
    final MonoEventData data = MonoEventData.fromJson(eventData.getKey('data'));
    widget.callbacks?.onEvent?.call(event, data);
  }

  /// Close the WebView and pop navigation
  void _closeWebView(String? result) {
    if (!mounted || _hasClosed) return;

    _hasClosed = true;
    Navigator.of(context).pop(result);
  }

  void _retryConnection() {
    _logger.info('Retrying connection');
    _hasError.value = false;
    _webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Material(
        child: GestureDetector(
          onTap: _dismissKeyboard,
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: WebViewWidget(
                    key: _key,
                    controller: _webViewController,
                    gestureRecognizers: _buildGestureRecognizers(),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _isLoading,
                  builder: (_, isLoading, _) {
                    if (!isLoading) return const SizedBox.shrink();

                    return widget.loadingWidget ??
                        const Center(child: CupertinoActivityIndicator());
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _hasError,
                  builder: (_, hasError, _) {
                    if (!hasError) return const SizedBox.shrink();

                    if (widget.errorWidgetBuilder != null) {
                      return widget.errorWidgetBuilder!(_retryConnection);
                    }

                    return _DefaultErrorWidget(onReload: _retryConnection);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Configure gesture recognizers for better touch handling
  Set<Factory<OneSequenceGestureRecognizer>> _buildGestureRecognizers() {
    return {
      Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
      Factory<TapGestureRecognizer>(
        () => TapGestureRecognizer()..onTapDown = (_) => _dismissKeyboard(),
      ),
    };
  }

  /// Dismiss keyboard when tapping outside input fields
  void _dismissKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Sorry, we could not connect to Mono.\nPlease check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
