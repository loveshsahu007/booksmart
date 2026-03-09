import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';

import '../utils/supabase.dart';

/// provide bank_id to refresh token
Future getPlaidToken({int? bankId}) async {
  return GetConnect()
      .post(
        'https://pvppwmkswnluidlwnnck.supabase.co/functions/v1/get_plad_token',
        bankId == null ? {} : {'bank_id': bankId},
        headers: {
          'Authorization':
              'Bearer ${supabase.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
      )
      .then((response) {
        log(jsonEncode(response.bodyString));
        if (response.isOk) {
          String? linkToken = response.body['link_token'];
          return linkToken;
        }
        return null;
      })
      .onError((e, x) {
        log(e.toString());
        log(x.toString());
        return null;
      });
}

Future<bool> connectPlaidBank(Map<String, dynamic> body) async {
  return GetConnect()
      .post(
        'https://pvppwmkswnluidlwnnck.supabase.co/functions/v1/plaid-connect-bank',
        body,
        headers: {
          'Authorization':
              'Bearer ${supabase.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
      )
      .then((value) {
        return true;
      })
      .onError((e, x) {
        log(e.toString());
        log(x.toString());
        return false;
      });
}

Future<bool> refreshPlaidAccessToken({
  required int bankId,
  required String publicToken,
}) async {
  return GetConnect()
      .post(
        'https://pvppwmkswnluidlwnnck.supabase.co/functions/v1/plaid_refresh_access_token',
        {'bank_id': bankId, 'public_token': publicToken},
        headers: {
          'Authorization':
              'Bearer ${supabase.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
      )
      .then((response) {
        log(jsonEncode(response.bodyString));
        if (response.isOk) {
          return true;
        }
        return false;
      })
      .onError((e, x) {
        log(e.toString());
        log(x.toString());
        return false;
      });
}

///{
///  "success": true,
///  "bank_id": 1,
///  "loops": 1,
///
///  "stats": {
///    "added": 0,
///    "modified": 0,
///    "removed": 0,
///    "upserted": 0,
///    "deleted": 0
///  },
///
///  "last_synced_at": "2026-01-21T06:26:14.797Z"
///}
Future<Map<String, dynamic>?> syncBankTransactions(int bankId) async {
  return GetConnect()
      .post(
        'https://pvppwmkswnluidlwnnck.supabase.co/functions/v1/plad_transaction_sync',
        {'bank_id': bankId},
        headers: {
          'Authorization':
              'Bearer ${supabase.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
      )
      .then((response) {
        log(jsonEncode(response.bodyString));
        if (response.isOk) {
          return response.body as Map<String, dynamic>?;
        }
        return null;
      })
      .onError((e, x) {
        log(e.toString());
        log(x.toString());
        return null;
      });
}

enum StripeCardAction {
  create_setup_intent,
  list_cards,
  set_default_card,
  delete_card,
}

/// Payload can be null if [action] is list_cards,
Future<Map<String, dynamic>> handleStripeCardManagement({
  required StripeCardAction action,
  String? paymentMethodId,
  bool isTestMode = true,
}) async {
  final String url =
      'https://pvppwmkswnluidlwnnck.supabase.co/functions/v1/stripe_card_manager${isTestMode ? "?test=true" : ""}';

  final session = supabase.auth.currentSession;
  if (session == null) throw Exception("User not logged in");

  final response = await GetConnect().post(
    url,
    jsonEncode({
      'action': action.name,
      'payload': paymentMethodId == null
          ? {}
          : {"payment_method_id": paymentMethodId},
    }),
    headers: {
      'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
      'Content-Type': 'application/json',
    },
  );
  log(response.bodyString ?? "handleStripeCardManagement ::: null");

  if (response.statusCode != 200) {
    throw Exception('Error: ${response.body}');
  }

  return jsonDecode(response.bodyString ?? "{}") as Map<String, dynamic>;
}

enum StripeBusinessAccountAction {
  create_account,
  start_onboarding,
  open_dashboard,
  get_business_account_info,
}

///
/// {
///   "success": true,
///   "account_exists": true,
///   "stripe_account_id": "acct_1T8pVpR84xNUdMa7",
///   "onboarding_complete": true,
///   "payouts_enabled": true,
///   "charges_enabled": true,
///   "pending_requirements": [],
///   "balance_available": 0,
///   "balance_pending": 0
/// }
Future<Map<String, dynamic>> callStripeCPA({
  required StripeBusinessAccountAction action,
  Map<String, dynamic>? payload,
  bool isTestMode = true,
}) async {
  final session = supabase.auth.currentSession;
  if (session == null) throw Exception("User not logged in");

  final url = Uri.parse(
    'https://pvppwmkswnluidlwnnck.supabase.co/functions/v1/stripe_connect${isTestMode ? "?test=true" : ""}',
  );

  final response = await GetConnect().post(
    url.toString(),
    jsonEncode({'action': action.name, 'payload': payload ?? {}}),
    headers: {
      'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
      'Content-Type': 'application/json',
    },
  );

  log(response.bodyString ?? "callStripeCPA ::: null");

  if (response.statusCode != 200) {
    throw Exception(response.bodyString ?? 'Unknown error');
  }

  return jsonDecode(response.bodyString ?? '{}') as Map<String, dynamic>;
}
