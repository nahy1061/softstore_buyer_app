import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import 'remote_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistToggle;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageSection(product: product, onWishlistToggle: onWishlistToggle),
            _InfoSection(product: product),
          ],
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final Product product;
  final VoidCallback? onWishlistToggle;
  const _ImageSection({required this.product, this.onWishlistToggle});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Product image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
          child: RemoteImage(
            url: product.imageUrl,
            width: double.infinity,
            height: 140,
            fit: BoxFit.cover,
          ),
        ),
        // Out of stock overlay
        if (!product.inStock)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: Text(
                    'OUT OF STOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Discount badge
        if (product.hasDiscount && product.inStock)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${product.discountPercent.toInt()}% OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Wishlist button
        if (onWishlistToggle != null)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onWishlistToggle,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
                ),
                child: Icon(
                  product.isWishlisted == true ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: product.isWishlisted == true ? AppColors.danger : Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Product product;
  const _InfoSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            product.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
          ),
          const SizedBox(height: 5),
          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'PKR ${product.displayPrice.toInt()}',
                style: const TextStyle(
                  color: AppColors.brandOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              if (product.hasDiscount) ...[
                const SizedBox(width: 5),
                Text(
                  'PKR ${product.displayListPrice.toInt()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          // Seller name
          if (product.sellerName != null && product.sellerName!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              product.sellerName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
          // Stock indicator
          if (!product.inStock) ...[
            const SizedBox(height: 3),
            const Text(
              'Out of stock',
              style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}
