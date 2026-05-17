import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class PaymentMethodScreen extends StatefulWidget {

  const PaymentMethodScreen({
    required this.bookingId,
    required this.booking,
    super.key,
  });
  final String bookingId;
  final Booking booking;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  late PaymentService _paymentService;
  late BookingService _bookingService;
  late PageController _pageController;

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
    _bookingService = BookingService();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      Get.snackbar(
        'Error',
        'Please fill in all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _paymentService.initialize();
      await _bookingService.initialize();
      
      // Prepare booking summary from the booking object we have in memory
      final bookingSummaryData = {
        'productName': widget.booking.productName,
        'quantity': widget.booking.quantity,
        'productPrice': widget.booking.productPrice,
        'totalPrice': widget.booking.totalPrice,
        'bookingType': widget.booking.bookingType,
        'bookingDate': widget.booking.bookingDate,
        'startDate': widget.booking.startDate,
        'endDate': widget.booking.endDate,
      };

      await _paymentService.processPayment(
        bookingId: widget.bookingId,
        paymentMethod: _selectedPaymentMethod,
        amount: widget.booking.totalPrice,
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
        bookingSummaryData: bookingSummaryData,
        shopOwnerIdOverride: widget.booking.shopOwnerId,
      );

      // After payment succeeds, confirm the booking and update payment status
      try {
        // Update payment status to COMPLETED
        await _bookingService.updatePaymentStatus(
          bookingId: widget.bookingId,
          paymentStatus: 'COMPLETED',
        );
        
        // Confirm the booking (move from UNPAID to PENDING and set userConfirmed to true)
        await _bookingService.confirmBookingByUser(bookingId: widget.bookingId);
        
        // Send notification to shop owner about the new booking
        try {
          final notificationService = NotificationService();
          await notificationService.createNotification(
            userId: widget.booking.shopOwnerId,
            title: 'New Booking Received',
            message: '${widget.booking.userName ?? 'A customer'} booked ${widget.booking.productName}',
            type: 'booking_request',
            bookingId: widget.bookingId,
            relatedUserId: widget.booking.userId,
            data: {
              'productName': widget.booking.productName,
              'quantity': widget.booking.quantity,
              'totalPrice': widget.booking.totalPrice,
              'customerName': widget.booking.userName,
              'bookingType': widget.booking.bookingType,
            },
          );
        } catch (notifError) {
          print('Error sending notification: $notifError');
          // Continue anyway - booking was successful
        }
      } catch (e) {
        print('Error updating booking after payment: $e');
        // Continue anyway - payment was successful
      }

      if (mounted) {
        Get.snackbar(
          'Payment Successful',
          'Your payment has been processed successfully',
          backgroundColor: const Color(0xFF1EDDAC),
          colorText: Colors.white,
        );

        // If product is from shop owner, go to landing page
        // If product is user-created listing, go to my bookings
        final navigationRoute = widget.booking.isUserListing ? '/my-bookings' : '/discover';
        
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAllNamed(navigationRoute);
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Payment Failed',
          'Unable to process payment. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      setState(() => _isProcessing = false);
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
              // Booking Summary
              _buildBookingSummary(),
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

  Widget _buildBookingSummary() => Container(
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
            'Booking Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Product', widget.booking.productName),
          const SizedBox(height: 8),
          _buildSummaryRow('Quantity', '${widget.booking.quantity}'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Price per Item',
            '₱${widget.booking.productPrice.toStringAsFixed(2)}',
          ),
          const Divider(height: 16),
          _buildSummaryRow(
            'Total Amount',
            '₱${widget.booking.totalPrice.toStringAsFixed(2)}',
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
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.white,
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
                isDateField: true,
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
    bool isDateField = false,
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
          readOnly: isDateField,
          style: const TextStyle(color: Colors.white),
          onTap: isDateField
              ? () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(now.year + 5, now.month, 1),
                    firstDate: now,
                    lastDate: DateTime(now.year + 20),
                  );
                  if (picked != null) {
                    final expiryDate = '${picked.month.toString().padLeft(2, '0')}/${picked.year.toString().substring(2)}';
                    controller.text = expiryDate;
                  }
                }
              : null,
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
                'Pay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
}
