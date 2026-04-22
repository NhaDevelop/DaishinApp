import 'package:flutter/material.dart';
import '../../widgets/common/app_logo.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

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
            Text('Delivery Addresses'),
          ],
        ),
      ),
      body: const Center(child: Text('Addresses Screen - To be implemented')),
    );
  }
}
