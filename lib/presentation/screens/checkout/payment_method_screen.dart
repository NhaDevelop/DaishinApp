import 'package:flutter/material.dart';
import '../../widgets/common/app_logo.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

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
            Text('Payment Method'),
          ],
        ),
      ),
      body: const Center(
        child: Text('Payment Method Screen - To be implemented'),
      ),
    );
  }
}
