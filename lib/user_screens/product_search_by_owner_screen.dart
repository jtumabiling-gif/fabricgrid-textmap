import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/product_details_service.dart';
import '../theme/app_theme.dart';

class ProductSearchByShopOwnerScreen extends StatefulWidget {
  const ProductSearchByShopOwnerScreen({super.key});

  @override
  State<ProductSearchByShopOwnerScreen> createState() =>
      _ProductSearchByShopOwnerScreenState();
}

class _ProductSearchByShopOwnerScreenState
    extends State<ProductSearchByShopOwnerScreen> {
  late ProductDetailsService _productDetailsService;
  final TextEditingController _shopOwnerController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _productDetailsService = ProductDetailsService();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _productDetailsService.initialize();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize service: $e';
        });
      }
    }
  }

  Future<void> _searchProducts() async {
    if (_shopOwnerController.text.isEmpty && _productNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter at least shop owner name or product name';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results =
          await _productDetailsService.searchProductsByShopOwnerAndProductName(
        shopOwnerName: _shopOwnerController.text.trim(),
        productName: _productNameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasSearched = true;

          if (results.isEmpty) {
            _errorMessage =
                'No products found matching your search criteria.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSearching = false;
          _hasSearched = true;
        });
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _shopOwnerController.clear();
      _productNameController.clear();
      _searchResults = [];
      _errorMessage = null;
      _hasSearched = false;
    });
  }

  Widget _buildAvatarWithInitials(String name, {double size = 40}) {
    final initials = name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.secondaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          initials.length > 2 ? initials.substring(0, 2) : initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0F1F2F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1F2F),
          elevation: 0,
          title: const Text(
            'Search Products',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: Get.back,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Search Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search by Shop Owner or Product Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Shop Owner Name Input
                    TextField(
                      controller: _shopOwnerController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter shop owner name...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.store,
                          color: AppTheme.primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A3A4F),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1A2332),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Product Name Input
                    TextField(
                      controller: _productNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter product name...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.shopping_bag,
                          color: AppTheme.primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A3A4F),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1A2332),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search and Clear Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isSearching ? null : _searchProducts,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              disabledBackgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.5),
                            ),
                            child: _isSearching
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Search'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red.withOpacity(0.3),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Clear'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Error Message
              if (_errorMessage != null && _hasSearched)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Results Section
              if (_hasSearched && _searchResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found ${_searchResults.length} product${_searchResults.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final productData = _searchResults[index];
                          final product = productData['product'];
                          final shopOwner =
                              productData['shopOwnerProfile'];

                          return GestureDetector(
                            onTap: () {
                              Get.toNamed('/product-detail', arguments: product);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A2332),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withOpacity(0.2),
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _buildAvatarWithInitials(
                                        shopOwner.shopName,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.productName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              shopOwner.shopName,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${product.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color:
                                                  AppTheme.primaryColor,
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Color(0xFFFFB800),
                                                size: 12,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                product.rating
                                                    .toStringAsFixed(1),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    product.description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Stock: ${product.stockQuantity}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: product.status ==
                                                  'AVAILABLE'
                                              ? Colors.green
                                                  .withOpacity(0.2)
                                              : Colors.red
                                                  .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          product.status,
                                          style: TextStyle(
                                            color: product.status ==
                                                    'AVAILABLE'
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

              // Empty State
              if (_hasSearched && _searchResults.isEmpty && _errorMessage == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No products found',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
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

  @override
  void dispose() {
    _shopOwnerController.dispose();
    _productNameController.dispose();
    super.dispose();
  }
}
