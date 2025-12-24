import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CpaListScreenAdmin extends StatefulWidget {
  const CpaListScreenAdmin({super.key});

  @override
  State<CpaListScreenAdmin> createState() => _CpaListScreenAdminState();
}

class _CpaListScreenAdminState extends State<CpaListScreenAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("CPAs")),
      body: const Center(child: Text("CPAs")),
    );
  }
}
