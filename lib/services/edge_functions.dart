import 'dart:developer';

import 'package:get/get.dart';

import '../utils/supabase.dart';

Future getPlaidToken() async {
  return GetConnect()
      .get(
        'https://pvppwmkswnluidlwnnck.supabase.co/functions/v1/get_plad_token',
        headers: {
          'Authorization':
              'Bearer ${supabase.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
      )
      .then((value) {
        String? linkToken = value.body['link_token'];
        return linkToken;
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
      .then((value) {
        return value.body as Map<String, dynamic>?;
      })
      .onError((e, x) {
        log(e.toString());
        log(x.toString());
        return null;
      });
}
