import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final double? minRating;
  final double? minPrice;
  final double? maxPrice;
  final Function(String?) onCategoryChanged;
  final Function(double?) onMinRatingChanged;
  final Function(double?, double?) onPriceRangeChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const FilterBottomSheet({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.minRating,
    required this.minPrice,
    required this.maxPrice,
    required this.onCategoryChanged,
    required this.onMinRatingChanged,
    required this.onPriceRangeChanged,
    required this.onReset,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _selectedCategory;
  late double? _minRating;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _minRating = widget.minRating;
    _minPriceController = TextEditingController(
      text: widget.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.maxPrice?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _handleApply() {
    widget.onCategoryChanged(_selectedCategory);
    widget.onMinRatingChanged(_minRating);
    
    final minPrice = _minPriceController.text.isEmpty
        ? null
        : double.tryParse(_minPriceController.text);
    final maxPrice = _maxPriceController.text.isEmpty
        ? null
        : double.tryParse(_maxPriceController.text);
    
    widget.onPriceRangeChanged(minPrice, maxPrice);
    widget.onApply();
  }

  void _handleReset() {
    setState(() {
      _selectedCategory = null;
      _minRating = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category Filter
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              hintText: 'All Categories',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Categories'),
              ),
              ...widget.categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),

          const SizedBox(height: 20),

          // Minimum Rating Filter
          const Text(
            'Minimum Rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final rating = (index + 1).toDouble();
              final isSelected = _minRating != null && _minRating! >= rating;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _minRating = _minRating == rating ? null : rating;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star,
                          color: isSelected ? Colors.amber : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${rating.toInt()}+',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Price Range Filter
          const Text(
            'Price Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min Price',
                    prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Price',
                    prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleReset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _handleApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
