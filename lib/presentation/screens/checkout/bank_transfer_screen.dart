import 'package:flutter/material.dart';
import '../../widgets/common/app_logo.dart';

class BankTransferScreen extends StatelessWidget {
  const BankTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            AppBarLogo(),
            SizedBox(width: 8),
            Text('Bank Transfer'),
          ],
        ),
      ),
      body: const Center(
        child: Text('Bank Transfer Screen - To be implemented'),
      ),
    );
  }
}
