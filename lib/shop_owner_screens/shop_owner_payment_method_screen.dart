import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/payment_service.dart';
import '../services/shop_owner_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class ShopOwnerPaymentMethodScreen extends StatefulWidget {

  const ShopOwnerPaymentMethodScreen({
    required this.planName,
    required this.price,
    required this.commission,
    required this.period,
    super.key,
  });
  final String planName;
  final String price;
  final String commission;
  final String period;

  @override
  State<ShopOwnerPaymentMethodScreen> createState() =>
      _ShopOwnerPaymentMethodScreenState();
}

class _ShopOwnerPaymentMethodScreenState
    extends State<ShopOwnerPaymentMethodScreen> {
  late PaymentService _paymentService;
  late SubscriptionService _subscriptionService;
  late ShopOwnerService _shopOwnerService;

  String _selectedPaymentMethod = 'CREDIT_CARD';
  bool _isProcessing = false;

  // Form controllers
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _subscriptionService = SubscriptionService();
    _shopOwnerService = ShopOwnerService();
  }

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _phoneNumberController.dispose();
    _bankNameController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_validateForm()) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _paymentService.initialize();

      final paymentId = await _paymentService.processPayment(
        bookingId: 'subscription_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: _selectedPaymentMethod,
        amount: _parsePrice(widget.price),
        currency: 'PHP',
        cardHolderName: _selectedPaymentMethod == 'CREDIT_CARD' || _selectedPaymentMethod == 'DEBIT_CARD'
            ? _cardHolderController.text
            : null,
        cardNumber: _selectedPaymentMethod == 'CREDIT_CARD' || _selectedPaymentMethod == 'DEBIT_CARD'
            ? _cardNumberController.text
            : null,
        expiryDate: _selectedPaymentMethod == 'CREDIT_CARD' || _selectedPaymentMethod == 'DEBIT_CARD'
            ? _expiryController.text
            : null,
        cvv: _selectedPaymentMethod == 'CREDIT_CARD' || _selectedPaymentMethod == 'DEBIT_CARD'
            ? _cvvController.text
            : null,
        phoneNumber: _selectedPaymentMethod == 'E_WALLET' ? _phoneNumberController.text : null,
        bankName: _selectedPaymentMethod == 'BANK_TRANSFER' ? _bankNameController.text : null,
        accountHolderName: _selectedPaymentMethod == 'BANK_TRANSFER' ? _accountHolderController.text : null,
      );

      // Get shop owner profile and save subscription
      final shopOwnerProfile = await _shopOwnerService.getCurrentShopOwnerProfile();
      
      if (shopOwnerProfile != null) {
        final commissionStr = widget.commission.replaceAll('%', '').trim();
        final commissionDouble = double.tryParse(commissionStr) ?? 0.0;

        await _subscriptionService.saveSubscription(
          planName: widget.planName,
          price: widget.price,
          commission: commissionDouble,
          paymentMethod: _getPaymentMethodName(_selectedPaymentMethod),
          shopOwnerProfile: shopOwnerProfile,
        );
      }

      if (mounted) {
        _showSuccessDialog(paymentId);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Payment Failed', 'Unable to process payment. Please try again.\nError: $e');
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  double _parsePrice(String price) {
    final cleanPrice = price.replaceAll('₱', '').trim();
    return double.tryParse(cleanPrice) ?? 0.0;
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'CREDIT_CARD':
        return 'Credit Card';
      case 'DEBIT_CARD':
        return 'Debit Card';
      case 'E_WALLET':
        return 'E-Wallet';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      default:
        return 'Unknown';
    }
  }

  bool _validateForm() {
    if (_selectedPaymentMethod == 'CREDIT_CARD' || _selectedPaymentMethod == 'DEBIT_CARD') {
      return _cardHolderController.text.isNotEmpty &&
          _cardNumberController.text.isNotEmpty &&
          _expiryController.text.isNotEmpty &&
          _cvvController.text.isNotEmpty;
    } else if (_selectedPaymentMethod == 'E_WALLET') {
      return _phoneNumberController.text.isNotEmpty;
    } else if (_selectedPaymentMethod == 'BANK_TRANSFER') {
      return _bankNameController.text.isNotEmpty && _accountHolderController.text.isNotEmpty;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.error.withOpacity(0.2),
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppTheme.error,
              size: 50,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  void _showSuccessDialog(String paymentId) {
    // Show success message
    Get.snackbar(
      'Payment Successful',
      'Your subscription payment has been confirmed',
      backgroundColor: const Color(0xFF1EDDAC),
      colorText: Colors.black87,
    );

    // Navigate back to shop owner main after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.offAllNamed('/shop_owner_main');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0F1F2F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1F2F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Subscription Summary
              _buildSubscriptionSummary(),
              const SizedBox(height: 24),
              // Payment Methods
              _buildPaymentMethods(),
              const SizedBox(height: 24),
              // Payment Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPaymentForm(),
              ),
              const SizedBox(height: 32),
              // Pay Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPayButton(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );

  Widget _buildSubscriptionSummary() => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Plan', widget.planName),
          const SizedBox(height: 8),
          _buildSummaryRow('Period', widget.period),
          const SizedBox(height: 8),
          _buildSummaryRow('Commission Rate', widget.commission),
          const Divider(height: 16, color: Colors.white24),
          _buildSummaryRow(
            'Monthly Amount',
            widget.price,
            isBold: true,
            color: Colors.white,
          ),
        ],
      ),
    );

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );

  Widget _buildPaymentMethods() {
    final methods = [
      {'id': 'CREDIT_CARD', 'label': 'Credit Card', 'icon': Icons.credit_card},
      {'id': 'DEBIT_CARD', 'label': 'Debit Card', 'icon': Icons.credit_card},
      {'id': 'E_WALLET', 'label': 'E-Wallet', 'icon': Icons.account_balance_wallet},
      {'id': 'BANK_TRANSFER', 'label': 'Bank Transfer', 'icon': Icons.account_balance},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ...methods.map((method) {
                final isSelected = _selectedPaymentMethod == method['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method['id']! as String;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1EDDAC) : const Color(0xFF1A2A3F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1EDDAC) : AppTheme.borderLight,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          method['icon']! as IconData,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          method['label']! as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedPaymentMethod == 'CREDIT_CARD' || _selectedPaymentMethod == 'DEBIT_CARD') {
      return _buildCardForm();
    } else if (_selectedPaymentMethod == 'E_WALLET') {
      return _buildEWalletForm();
    } else if (_selectedPaymentMethod == 'BANK_TRANSFER') {
      return _buildBankTransferForm();
    }
    return const SizedBox.shrink();
  }

  Widget _buildCardForm() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _cardHolderController,
          label: 'Cardholder Name',
          hint: 'John Doe',
          icon: Icons.person,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _cardNumberController,
          label: 'Card Number',
          hint: '1234 5678 9012 3456',
          icon: Icons.credit_card,
          maxLength: 16,
          inputType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _expiryController,
                label: 'Expiry Date',
                hint: 'MM/YY',
                icon: Icons.calendar_today,
                maxLength: 5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _cvvController,
                label: 'CVV',
                hint: '123',
                icon: Icons.lock,
                maxLength: 3,
                inputType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );

  Widget _buildEWalletForm() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'E-Wallet Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneNumberController,
          label: 'Phone Number',
          hint: '+63 912 345 6789',
          icon: Icons.phone,
          inputType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.info.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.info, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter the phone number linked to your e-wallet account',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

  Widget _buildBankTransferForm() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Transfer Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bankNameController,
          label: 'Bank Name',
          hint: 'BPI, BDO, MetroBank, etc.',
          icon: Icons.account_balance,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _accountHolderController,
          label: 'Account Holder Name',
          hint: 'John Doe',
          icon: Icons.person,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bank transfer details will be sent to you after confirmation',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
    TextInputType inputType = TextInputType.text,
  }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: inputType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: Icon(icon, color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF1A2A3F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );

  Widget _buildPayButton() => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1EDDAC),
          disabledBackgroundColor: const Color(0xFF1EDDAC).withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Pay Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
}
