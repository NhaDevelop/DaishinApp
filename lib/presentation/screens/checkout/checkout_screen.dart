import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../../utils/formatters.dart';
import '../../../core/routes/route_names.dart';
import '../../widgets/common/top_snackbar.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  final DateTime? suggestedDeliveryDate;

  const CheckoutScreen({super.key, this.suggestedDeliveryDate});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalItemsController = TextEditingController();
  final _productIdsController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMethod = 'bank_transfer';
  DateTime? _selectedDeliveryDate;
  bool _isProcessing = false;
  bool _isInitialized = false;
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = context.read<AuthProvider>();
      final cartProvider = context.read<CartProvider>();
      final user = authProvider.currentUser;

      if (user != null) {
        _customerIdController.text = user.id;
        _nameController.text = user.name; // Auto-fill name if available
        // _phoneController.text = user.phone; // Auto-fill phone if available (assuming user model has phone)
      }

      _totalItemsController.text = '${cartProvider.itemCount} items';
      _productIdsController.text =
          cartProvider.items.map((item) => item.product.id).join(', ');

      // Use suggested delivery date if provided (from repeat order)
      if (widget.suggestedDeliveryDate != null) {
        _selectedDeliveryDate = widget.suggestedDeliveryDate;
      }

      // Defer state update to next frame to avoid 'setState during build' error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OrderProvider>().loadPaymentMethods().then((_) {
          if (mounted) {
            final orderProvider = context.read<OrderProvider>();
            if (orderProvider.paymentMethods.isNotEmpty &&
                !orderProvider.paymentMethods
                    .any((element) => element.name == _paymentMethod)) {
              setState(() {
                _paymentMethod = orderProvider.paymentMethods.first.name;
              });
            }
          }
        });
      });

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _totalItemsController.dispose();
    _productIdsController.dispose();
    _notesController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if user can place orders
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      TopSnackBar.show(context, 'Please login to place an order',
          isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cartProvider = context.read<CartProvider>();
      final orderProvider = context.read<OrderProvider>();

      // Format delivery date if selected (yyyy-MM-dd format)
      if (_selectedDeliveryDate != null) {
        final formattedDeliveryDate =
            DateFormat('yyyy-MM-dd').format(_selectedDeliveryDate!);
        print('📅 Updating Delivery Date: $formattedDeliveryDate');

        // Call update_delivery_date API first
        await orderProvider.updateDeliveryDate(formattedDeliveryDate);
      }

      // Then call the submit_order endpoint
      final result = await orderProvider.submitOrder();

      if (result['status'] == 1) {
        // Clear cart on success
        await cartProvider.clearCart();

        if (mounted) {
          context.go(RouteNames.orderList);
          TopSnackBar.show(
              context, result['message'] ?? 'Order placed successfully!');
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to submit order');
      }
    } catch (e) {
      if (mounted) {
        TopSnackBar.show(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _updatePaymentMethod(String paymentMethod) async {
    final orderProvider = context.read<OrderProvider>();
    await orderProvider.updatePaymentMethod(paymentMethod);
  }

  void _onNoteChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        // API returns error for empty string, so valid only if not empty
        // or send a space if needed to clear? For now, prevent empty call.
        if (value.trim().isNotEmpty) {
          context.read<OrderProvider>().updateOrderNote(value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Padding(
              padding: EdgeInsets.all(4.0),
              child: AppBarLogo(),
            ),
            SizedBox(width: 8),
            Text('Checkout'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.go(RouteNames.products);
            },
            icon: const Icon(Icons.store),
            tooltip: 'Go to Shop',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Information Card
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final user = authProvider.currentUser;
                        if (user == null) return const SizedBox.shrink();

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_circle,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Customer Information',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildUserInfoRow(
                                context,
                                Icons.person_outline,
                                'Name',
                                user.name,
                              ),
                              const SizedBox(height: 12),
                              _buildUserInfoRow(
                                context,
                                Icons.email_outlined,
                                'Email',
                                user.email,
                              ),
                              if (user.phone != null &&
                                  user.phone!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildUserInfoRow(
                                  context,
                                  Icons.phone_outlined,
                                  'Phone',
                                  user.phone!,
                                ),
                              ],
                              const SizedBox(height: 12),
                              _buildUserInfoRow(
                                context,
                                Icons.badge_outlined,
                                'Customer ID',
                                user.id,
                              ),
                              if (user.address != null &&
                                  user.address!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildUserInfoRow(
                                  context,
                                  Icons.location_on_outlined,
                                  'Address',
                                  user.address!,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Delivery Information

                    // Auto-filled Order Info Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Added Header inside Container
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined, // Delivery Icon
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delivery Information',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCompactInfoRow(
                            context,
                            'Customer ID',
                            _customerIdController.text,
                            Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _buildCompactInfoRow(
                            context,
                            'Total Products',
                            _totalItemsController.text,
                            Icons.shopping_bag_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildCompactInfoRow(
                            context,
                            'Product IDs',
                            _productIdsController.text,
                            Icons.qr_code_2_outlined,
                            isMultiLine: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Delivery Policy Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Orders before 5:00 PM → Same-day delivery\nOrders after 5:00 PM → Next-day delivery',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Delivery Date
                    Text(
                      'Delivery Date',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4), // Add padding for shadow
                      child: Row(
                        children: [
                          // Custom Date Picker Card
                          Builder(builder: (context) {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            return InkWell(
                              onTap: () async {
                                final initialDate =
                                    _selectedDeliveryDate ?? DateTime.now();
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: initialDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 30)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: isDark
                                            ? ColorScheme.dark(
                                                primary: Theme.of(context)
                                                    .primaryColor,
                                                onPrimary: Colors.white,
                                                surface:
                                                    const Color(0xFF1E1E1E),
                                              )
                                            : ColorScheme.light(
                                                primary: Theme.of(context)
                                                    .primaryColor,
                                                onPrimary: Colors.white,
                                              ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (pickedDate != null) {
                                  setState(() {
                                    _selectedDeliveryDate = pickedDate;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 90,
                                height:
                                    98, // Match height of date cards roughly
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(isDark ? 0.0 : 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.calendar_month_rounded,
                                        size: 20,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (_selectedDeliveryDate != null &&
                                              !DateUtils.isSameDay(
                                                  _selectedDeliveryDate!,
                                                  DateTime.now()) &&
                                              !DateUtils.isSameDay(
                                                  _selectedDeliveryDate!,
                                                  DateTime.now().add(
                                                      const Duration(
                                                          days: 1))) &&
                                              !DateUtils.isSameDay(
                                                  _selectedDeliveryDate!,
                                                  DateTime.now().add(
                                                      const Duration(days: 2))))
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_selectedDeliveryDate!)
                                          : 'Other Date',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 12),
                          _buildDateOption(
                            context,
                            DateTime.now(),
                            'Today',
                          ),
                          const SizedBox(width: 12),
                          _buildDateOption(
                            context,
                            DateTime.now().add(const Duration(days: 1)),
                            'Tomorrow',
                          ),
                          const SizedBox(width: 12),
                          _buildDateOption(
                            context,
                            DateTime.now().add(const Duration(days: 2)),
                            DateFormat('EEEE').format(DateTime.now().add(
                                const Duration(
                                    days: 2))), // Day name e.g. Wednesday
                          ),
                        ],
                      ),
                    ),
                    if (_selectedDeliveryDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Selected: ${DateFormat('EEEE, d MMMM y').format(_selectedDeliveryDate!)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Payment Method
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<OrderProvider>(
                      builder: (context, orderProvider, child) {
                        if (orderProvider.paymentMethodsState.isLoading) {
                          return const Center(
                              child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        final methods = orderProvider.paymentMethods;

                        // Fallback/Default if empty
                        if (methods.isEmpty) {
                          return Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text('Bank Transfer'),
                                subtitle: const Text('Pay via bank transfer'),
                                value: 'bank_transfer',
                                groupValue: _paymentMethod,
                                onChanged: (value) =>
                                    setState(() => _paymentMethod = value!),
                              ),
                              RadioListTile<String>(
                                title: const Text('Cash on Delivery'),
                                subtitle: const Text('Pay when you receive'),
                                value: 'cod',
                                groupValue: _paymentMethod,
                                onChanged: (value) =>
                                    setState(() => _paymentMethod = value!),
                              ),
                            ],
                          );
                        }

                        // Dynamic List
                        return Column(
                          children: methods.map((method) {
                            return RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  if (method.image.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 12.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          method.image,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            IconData iconData = Icons.payment;
                                            if (method.name
                                                .toLowerCase()
                                                .contains('cod')) {
                                              iconData = Icons.local_shipping;
                                            } else if (method.name
                                                .toLowerCase()
                                                .contains('account')) {
                                              iconData = Icons.account_balance;
                                            }
                                            return Icon(iconData,
                                                size: 32, color: Colors.grey);
                                          },
                                        ),
                                      ),
                                    ),
                                  Text(
                                    method.displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              value: method.name,
                              groupValue: _paymentMethod,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (value) async {
                                setState(() => _paymentMethod = value!);
                                // Call API to update payment method
                                await _updatePaymentMethod(value!);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Order Notes
                    Text(
                      'Order Notes (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      onChanged: _onNoteChanged,
                      decoration: const InputDecoration(
                        hintText: 'Any special instructions?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal (${cartProvider.itemCount} items)',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(cartProvider.total),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // VAT Included
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VAT Included',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(cartProvider.vat),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(cartProvider.grandTotal),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Submit Order Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Proceed to Checkout',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).primaryColor.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: isMultiLine ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).primaryColor.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateOption(BuildContext context, DateTime date, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if selected (ignoring time)
    final isSelected = _selectedDeliveryDate != null &&
        _selectedDeliveryDate!.year == date.year &&
        _selectedDeliveryDate!.month == date.month &&
        _selectedDeliveryDate!.day == date.day;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDeliveryDate = date;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90, // Fixed width for nice cards
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('d').format(date),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM').format(date),
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
