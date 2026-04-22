import 'package:flutter/material.dart';
import '../../widgets/common/app_logo.dart';

class ReceiptUploadScreen extends StatelessWidget {
  const ReceiptUploadScreen({super.key});

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
            Text('Upload Receipt'),
          ],
        ),
      ),
      body: const Center(
        child: Text('Receipt Upload Screen - To be implemented'),
      ),
    );
  }
}
