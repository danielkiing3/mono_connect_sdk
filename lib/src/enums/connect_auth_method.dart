import 'package:mono_connect_sdk/src/core/extensions/iterable.dart';

enum ConnectAuthMethod {
  internetBanking("internet_banking"),
  mobileBanking("mobile_banking");

  final String value;

  const ConnectAuthMethod(this.value);

  static ConnectAuthMethod fromValue(String value) {
    final type = ConnectAuthMethod.values.firstWhereOrNull(
      (e) => e.value == value,
    );

    return type ?? ConnectAuthMethod.internetBanking;
  }
}
