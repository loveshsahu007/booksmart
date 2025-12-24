import 'package:booksmart/modules/admin/temp_admin_dashboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//
// Keep it empty for now
//
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Dashboard")),
      body: TempAdminDashboard(),
    );
  }
}
