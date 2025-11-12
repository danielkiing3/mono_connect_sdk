import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:mono_connect_sdk/src/core/constants/mono_connect_config_constant.dart';
import 'package:mono_connect_sdk/src/models/connect_institution.dart';
import 'package:mono_connect_sdk/src/models/mono_customer.dart';

/// Configuration for Mono Connect WebView
@immutable
class MonoConnectConfig {
  /// Public API key from Mono dashboard
  final String apiKey;

  /// The customer objects expects the following keys based on the following conditions:
  /// New Customers: For new customers, the customer object expects the user’s name, email and identity
  /// Existing Customers: For existing customers, the customer object expects only the customer ID.
  final MonoCustomer customer;

  /// Re-authentication token for returning users
  final String reAuthCode;

  /// Optional transaction reference
  final String? reference;

  /// Connect scope (default: 'auth')
  final String scope;

  /// Optional payment URL for direct payment
  final String? paymentUrl;

  /// Pre-selected institution
  final ConnectInstitution? selectedInstitution;

  const MonoConnectConfig({
    required this.apiKey,
    required this.customer,
    this.reAuthCode = '',
    this.reference,
    this.scope = 'auth',
    this.paymentUrl,
    this.selectedInstitution,
  });

  /// Build the URI for Mono Connect
  Uri buildConnectUri() {
    final String customerData = jsonEncode({'customer': customer.toMap()});
    final String? institutionData = selectedInstitution?.toJson();

    return Uri(
      scheme: MonoConnectConfigConstant.urlScheme,
      host: MonoConnectConfigConstant.connectHost,
      queryParameters: {
        'key': apiKey,
        'version': MonoConnectConfigConstant.version,
        'scope': scope,
        'data': customerData,
        'reauth_token': reAuthCode,
        if (reference != null) 'reference': reference,
        if (institutionData != null) 'selectedInstitution': institutionData,
      },
    );
  }
}
