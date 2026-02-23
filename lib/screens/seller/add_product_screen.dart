import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/colors.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _selectedCategory;
  bool _isUploading = false;

  bool get isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _titleController.text = widget.product!.title;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      final productCategory = widget.product!.category;
      final matchingCategory = productCategories.firstWhere(
        (cat) => cat.toLowerCase() == productCategory.toLowerCase(),
        orElse: () => productCategories.first,
      );
      _selectedCategory = matchingCategory;
    } else {
      _selectedCategory = productCategories.first;
      _stockController.text = '0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable photo permission in settings'),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo permission is required')),
      );
    }
    return false;
  }

  Future<void> _pickImage() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (!isEditMode && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product image')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final currentUser = authProvider.currentUser!;
      final sellerProfile = authProvider.userModel;

      if (isEditMode) {
        await productProvider.updateProduct(
          productId: widget.product!.id,
          sellerId: currentUser.uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory!,
          stock: int.parse(_stockController.text.trim()),
          originLat: sellerProfile?.locationLat,
          originLng: sellerProfile?.locationLng,
          originCity: sellerProfile?.city,
          imageFile: _selectedImage,
        );
      } else {
        await productProvider.addProduct(
          sellerId: currentUser.uid,
          sellerName:
              (sellerProfile?.name != null && sellerProfile!.name.isNotEmpty)
                  ? sellerProfile.name
                  : (currentUser.email ?? 'Unknown Seller'),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory!,
          stock: int.parse(_stockController.text.trim()),
          originLat: sellerProfile?.locationLat,
          originLng: sellerProfile?.locationLng,
          originCity: sellerProfile?.city,
          imageFile: _selectedImage!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode
                ? 'Product updated successfully!'
                : 'Product listed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Shared input decoration ─────────────────────────────────────────────────
  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
      filled: true,
      fillColor: AppColors.primarySurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      prefixIcon: Icon(icon, color: AppColors.primaryAccent, size: 20),
      suffixText: suffix,
      suffixStyle: GoogleFonts.inter(
          fontSize: 13, color: AppColors.textSecondary),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  // ── Section card wrapper ────────────────────────────────────────────────────
  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode ? 'Edit Product' : 'New Product',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              isEditMode ? 'Update your listing' : 'List a new item',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      // ── Sticky save button ────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.softAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isUploading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEditMode ? 'Updating…' : 'Listing…',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : Text(
                      isEditMode ? 'Update Product' : 'List Product',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          children: [
            // ── Image picker ───────────────────────────────────────────────
            _sectionCard(
              title: 'PRODUCT PHOTO',
              child: GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Image or placeholder
                      Container(
                        height: 210,
                        width: double.infinity,
                        color: AppColors.secondarySurface,
                        child: _selectedImage != null
                            ? FutureBuilder<Uint8List>(
                                future: _selectedImage!.readAsBytes(),
                                builder: (_, snap) {
                                  if (snap.hasData) {
                                    return Image.memory(snap.data!,
                                        fit: BoxFit.cover);
                                  }
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                              )
                            : isEditMode &&
                                    widget.product!.imageUrl.isNotEmpty
                                ? Image.network(
                                    widget.product!.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imagePlaceholder(),
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                          child:
                                              CircularProgressIndicator());
                                    },
                                  )
                                : _imagePlaceholder(),
                      ),

                      // Edit overlay (shown when image already selected)
                      if (_selectedImage != null ||
                          (isEditMode &&
                              widget.product!.imageUrl.isNotEmpty))
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Change Photo',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Title & description ────────────────────────────────────────
            _sectionCard(
              title: 'PRODUCT DETAILS',
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isUploading,
                    maxLength: 80,
                    style: GoogleFonts.inter(
                        fontSize: 15, color: AppColors.textPrimary),
                    decoration: _inputDeco(
                      label: 'Product Title',
                      hint: 'e.g. Handwoven Khadi Scarf',
                      icon: Icons.title,
                    ).copyWith(counterText: ''),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Title is required';
                      }
                      if (v.trim().length < 3) {
                        return 'At least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isUploading,
                    maxLines: 4,
                    maxLength: 500,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5),
                    decoration: _inputDeco(
                      label: 'Description',
                      hint:
                          'Describe the material, craft technique, dimensions…',
                      icon: Icons.description_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Description is required';
                      }
                      if (v.trim().length < 10) {
                        return 'At least 10 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Price, stock, category ─────────────────────────────────────
            _sectionCard(
              title: 'PRICING & INVENTORY',
              child: Column(
                children: [
                  // Price + Stock in a row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          enabled: !_isUploading,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: GoogleFonts.inter(
                              fontSize: 15, color: AppColors.textPrimary),
                          decoration: _inputDeco(
                            label: 'Price',
                            hint: '0.00',
                            icon: Icons.currency_rupee,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            final p = double.tryParse(v.trim());
                            if (p == null || p <= 0) return 'Invalid price';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          enabled: !_isUploading,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                              fontSize: 15, color: AppColors.textPrimary),
                          decoration: _inputDeco(
                            label: 'Stock',
                            hint: '0',
                            icon: Icons.inventory_2_outlined,
                            suffix: 'units',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            final s = int.tryParse(v.trim());
                            if (s == null || s < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: _inputDeco(
                      label: 'Category',
                      hint: 'Select category',
                      icon: Icons.category_outlined,
                    ),
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textPrimary),
                    dropdownColor: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    items: productCategories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat,
                                  style: GoogleFonts.inter(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: _isUploading
                        ? null
                        : (v) => setState(() => _selectedCategory = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Select a category' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // space so content clears the FAB
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return SizedBox(
      height: 210,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 52, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(
            'Tap to add a photo',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'JPG or PNG, up to 5 MB',
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
