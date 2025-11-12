import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mono_connect_sdk/mono.dart';

void main() {
  runApp(const MyApp());
}

extension ContextExtension on BuildContext {
  double getHeight([double factor = 1]) {
    return MediaQuery.sizeOf(this).height * factor;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          spacing: 4,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    enableDrag: true,
                    isDismissible: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return MonoConnectView(
                        config: MonoConnectConfig(
                          apiKey: 'live_pk_i3bamg4plgftxom3ssei',
                          reference:
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          customer: const MonoCustomer(
                            newCustomer: MonoNewCustomerModel(
                              name: "Samuel Olamide",
                              email: "samuel@neem.com",
                              identity: MonoNewCustomerIdentity(
                                type: "bvn",
                                number: "2323233239",
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Text("Mono Connect SDK")),
            ElevatedButton(
              child: const Text('launch mono'),
              onPressed: () {
                // if (kIsWeb) {
                MonoFlutter().launchBottomSheet(
                  context,
                  'live_pk_i3bamg4plgftxom3ssei',
                  scope: "auth",
                  reference: DateTime.now().millisecondsSinceEpoch.toString(),
                  customer: const MonoCustomer(
                    newCustomer: MonoNewCustomerModel(
                      name: "Samuel Olamide", // REQUIRED
                      email: "samuel@neem.com", // REQUIRED
                      identity: MonoNewCustomerIdentity(
                        type: "bvn",
                        number: "2323233239",
                      ),
                    ),
                  ),
                  onEvent: (event, data) {
                    if (kDebugMode) print('event: $event, data: $data');
                  },
                  onClosed: (code) {
                    if (kDebugMode) print('Modal closed $code');
                  },
                  onLoad: () {
                    if (kDebugMode) print('Mono loaded successfully');
                  },
                  onSuccess: (code) {
                    if (kDebugMode) print('Mono Success $code');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
