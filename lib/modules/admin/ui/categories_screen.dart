import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Categories")),
      body: const Center(child: Text("Categories")),
    );
  }
}
