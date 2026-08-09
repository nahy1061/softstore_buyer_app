# Phase 3: Data Models

## Overview

All models are immutable (`final` fields) with `fromJson` factory constructors and `toJson` methods generated via `json_serializable`. Relationships are modeled as IDs (not nested objects) unless the API always returns them together.

---

## 1. User

**Backend table:** `marketplace_customers`

| Field | Dart Type | Required | Backend Column | Notes |
|-------|-----------|----------|----------------|-------|
| id | `int` | Yes | `id` | Primary key |
| fullName | `String` | Yes | `full_name` | Display name |
| firstName | `String?` | No | `first_name` | Split from full_name |
| lastName | `String?` | No | `last_name` | Split from full_name |
| email | `String` | Yes | `email` | Unique, login credential |
| phone | `String?` | No | `phone` | Pakistani format |
| emailVerified | `bool` | Yes | `email_verified` | OTP confirmed |
| createdAt | `DateTime` | Yes | `created_at` | Registration timestamp |

```dart
@JsonSerializable()
class UserModel {
  final int id;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final bool emailVerified;
  final DateTime createdAt;
}
```

---

## 2. Product (List Item)

**Backend table:** `products`

Used in product grids, search results, related products, wishlist.

| Field | Dart Type | Required | Backend Column | Notes |
|-------|-----------|----------|----------------|-------|
| id | `int` | Yes | `id` | Primary key |
| name | `String` | Yes | `product_name` | |
| slug | `String` | Yes | `slug` | URL-friendly |
| price | `double` | Yes | Computed | Tax-inclusive display price |
| listPrice | `double?` | No | Computed | Original price (before discount) |
| hasDiscount | `bool` | Yes | Computed | From PricingService |
| discountPercent | `int?` | No | Computed | e.g., 20 |
| imageUrl | `String` | Yes | `image_url` | Primary image thumbnail |
| sellerName | `String` | Yes | Joined | From seller/business table |
| sellerId | `int` | Yes | `tenant_id` | Foreign key |
| rating | `double?` | No | Computed | Average rating |
| reviewCount | `int` | Yes | Computed | Total reviews |
| inStock | `bool` | Yes | Computed | `quantity_on_hand > 0` |
| stockQuantity | `int?` | No | `quantity_on_hand` | For low-stock badge |
| freeDelivery | `bool` | Yes | Computed | Price >= threshold |
| fulfilmentChannel | `String` | Yes | `fulfilment_channel` | 'seller' or 'fba' |

```dart
@JsonSerializable()
class ProductModel {
  final int id;
  final String name;
  final String slug;
  final double price;
  final double? listPrice;
  final bool hasDiscount;
  final int? discountPercent;
  final String imageUrl;
  final String sellerName;
  final int sellerId;
  final double? rating;
  final int reviewCount;
  final bool inStock;
  final int? stockQuantity;
  final bool freeDelivery;
  final String fulfilmentChannel;
}
```

---

## 3. Product Detail

Extended product data for the detail screen.

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | |
| name | `String` | Yes | |
| slug | `String` | Yes | |
| description | `String?` | No | HTML or plain text |
| specifications | `Map<String, String>?` | No | Key-value pairs |
| pricing | `PricingModel` | Yes | Full pricing breakdown |
| gallery | `List<String>` | Yes | Image URLs (full-res) |
| variants | `List<VariantModel>` | Yes | Can be empty |
| reviews | `List<ReviewModel>` | Yes | First page |
| ratingBreakdown | `RatingBreakdown` | Yes | Star distribution |
| relatedProducts | `List<ProductModel>` | Yes | Up to 6 |
| availableStock | `int` | Yes | Current stock |
| seller | `SellerSummary` | Yes | Embedded seller card |
| whatsappUrl | `String?` | No | Conditional |
| isAgeRestricted | `bool` | Yes | Gate before add-to-cart |
| categoryBreadcrumb | `List<CategoryModel>` | Yes | For display |

```dart
@JsonSerializable()
class ProductDetailModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final Map<String, String>? specifications;
  final PricingModel pricing;
  final List<String> gallery;
  final List<VariantModel> variants;
  final List<ReviewModel> reviews;
  final RatingBreakdown ratingBreakdown;
  final List<ProductModel> relatedProducts;
  final int availableStock;
  final SellerSummary seller;
  final String? whatsappUrl;
  final bool isAgeRestricted;
  final List<CategoryModel> categoryBreadcrumb;
}
```

---

## 4. Pricing

**Backend service:** `PricingService::resolve()`

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| displayPrice | `double` | Yes | Final price buyer pays (tax-inclusive) |
| displayList | `double?` | No | Original price (strikethrough) |
| hasDiscount | `bool` | Yes | |
| discountPercent | `int?` | No | |
| taxRate | `double` | Yes | e.g., 0.17 |
| unitTax | `double` | Yes | Tax per unit |
| source | `String` | Yes | 'normal' or 'deal' |

```dart
@JsonSerializable()
class PricingModel {
  final double displayPrice;
  final double? displayList;
  final bool hasDiscount;
  final int? discountPercent;
  final double taxRate;
  final double unitTax;
  final String source;
}
```

---

## 5. Variant

**Backend:** Inline in product response

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | `variant_id` |
| option | `String` | Yes | e.g., "Size", "Color" |
| label | `String` | Yes | e.g., "Large", "Red" |
| price | `double` | Yes | Tax-inclusive variant price |

```dart
@JsonSerializable()
class VariantModel {
  final int id;
  final String option;
  final String label;
  final double price;
}
```

---

## 6. Category

**Backend table:** `categories`

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | |
| name | `String` | Yes | |
| slug | `String` | Yes | URL-friendly |
| productCount | `int?` | No | For display in category list |

```dart
@JsonSerializable()
class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final int? productCount;
}
```

---

## 7. Seller

**Backend table:** `businesses` / `tenants`

### SellerSummary (Embedded in Product Detail)

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | tenant_id |
| name | `String` | Yes | Business name |
| slug | `String` | Yes | Store URL slug |
| rating | `double?` | No | Average from store_ratings |
| city | `String?` | No | Location |

### SellerModel (Full, for Seller Store Page)

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | |
| name | `String` | Yes | |
| slug | `String` | Yes | |
| rating | `double?` | No | |
| city | `String?` | No | |
| logoUrl | `String?` | No | Store logo |
| bannerUrl | `String?` | No | Store banner |
| productCount | `int` | Yes | Total products |
| followerCount | `int` | Yes | From store_followers |
| isFollowing | `bool` | Yes | Current user's follow state |

```dart
@JsonSerializable()
class SellerModel {
  final int id;
  final String name;
  final String slug;
  final double? rating;
  final String? city;
  final String? logoUrl;
  final String? bannerUrl;
  final int productCount;
  final int followerCount;
  final bool isFollowing;
}
```

---

## 8. Cart & CartItem

**Storage:** Local (SharedPreferences as JSON string)

No backend table — cart lives on device.

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| items | `List<CartItem>` | Yes | Cart contents |
| updatedAt | `DateTime` | Yes | Last modification |

### CartItem

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| productId | `int` | Yes | |
| name | `String` | Yes | For offline display |
| price | `double` | Yes | Price at time of add (verified at checkout) |
| imageUrl | `String` | Yes | Thumbnail |
| quantity | `int` | Yes | Min 1 |
| variantId | `int?` | No | If variant selected |
| variantLabel | `String?` | No | e.g., "Red - Large" |
| sellerId | `int` | Yes | For multi-seller grouping |
| sellerName | `String` | Yes | For display |

```dart
@JsonSerializable()
class CartItem {
  final int productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final int? variantId;
  final String? variantLabel;
  final int sellerId;
  final String sellerName;
}
```

---

## 9. Address

**Backend table:** `marketplace_addresses`

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | Primary key |
| label | `String?` | No | "Home", "Office" |
| recipientName | `String` | Yes | |
| phone | `String` | Yes | |
| addressLine1 | `String` | Yes | Street address |
| addressLine2 | `String?` | No | Apt, floor, etc. |
| city | `String` | Yes | |
| state | `String?` | No | Province |
| postalCode | `String?` | No | |
| isDefault | `bool` | Yes | Default for checkout |

```dart
@JsonSerializable()
class AddressModel {
  final int id;
  final String? label;
  final String recipientName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String? postalCode;
  final bool isDefault;
}
```

---

## 10. Order

**Backend table:** `sales` (where `payment_method = 'marketplace'`)

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | Primary key |
| invoiceNumber | `String` | Yes | `MKT-{alphanumeric}` |
| status | `OrderStatus` | Yes | Enum |
| grandTotal | `double` | Yes | Final amount |
| subtotal | `double` | Yes | Before delivery/discount |
| taxAmount | `double` | Yes | |
| discountAmount | `double` | Yes | Coupon discount |
| deliveryFee | `double` | Yes | 0 or 199 |
| sellerName | `String` | Yes | Business name |
| sellerId | `int` | Yes | |
| itemsCount | `int` | Yes | Number of items |
| createdAt | `DateTime` | Yes | Order date |
| items | `List<OrderItem>?` | No | Only in detail view |
| timeline | `List<OrderTimelineEntry>?` | No | Only in detail view |
| deliveryAddress | `String?` | No | Full address string |
| customerName | `String?` | No | |
| customerPhone | `String?` | No | |
| paymentMethod | `String` | Yes | 'cod' |
| paymentStatus | `String` | Yes | 'pending'/'paid' |
| returnEligible | `bool?` | No | Within 7-day window |

```dart
enum OrderStatus {
  pending, confirmed, processing, shipped, delivered,
  cancelled, deliveryFailed, refunded
}

@JsonSerializable()
class OrderModel {
  final int id;
  final String invoiceNumber;
  final OrderStatus status;
  final double grandTotal;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double deliveryFee;
  final String sellerName;
  final int sellerId;
  final int itemsCount;
  final DateTime createdAt;
  final List<OrderItem>? items;
  final List<OrderTimelineEntry>? timeline;
  final String? deliveryAddress;
  final String? customerName;
  final String? customerPhone;
  final String paymentMethod;
  final String paymentStatus;
  final bool? returnEligible;
}
```

---

## 11. OrderItem

**Backend table:** `sale_items`

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | |
| productId | `int` | Yes | |
| productName | `String` | Yes | |
| sku | `String?` | No | |
| imageUrl | `String?` | No | |
| quantity | `int` | Yes | |
| unitPrice | `double` | Yes | |
| totalAmount | `double` | Yes | qty × unit price |
| variantLabel | `String?` | No | |

```dart
@JsonSerializable()
class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? sku;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String? variantLabel;
}
```

---

## 12. OrderTimelineEntry

**Backend table:** `order_status_history`

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| status | `OrderStatus` | Yes | New status |
| notes | `String?` | No | Seller note |
| createdAt | `DateTime` | Yes | When status changed |

```dart
@JsonSerializable()
class OrderTimelineEntry {
  final OrderStatus status;
  final String? notes;
  final DateTime createdAt;
}
```

---

## 13. Review

**Backend table:** `reviews` (inferred)

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | |
| rating | `int` | Yes | 1-5 |
| title | `String?` | No | Optional heading |
| comment | `String?` | No | Review text |
| authorName | `String` | Yes | Buyer display name |
| isVerifiedPurchase | `bool` | Yes | |
| createdAt | `DateTime` | Yes | |

```dart
@JsonSerializable()
class ReviewModel {
  final int id;
  final int rating;
  final String? title;
  final String? comment;
  final String authorName;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
}
```

### RatingBreakdown

| Field | Dart Type | Required |
|-------|-----------|----------|
| average | `double` | Yes |
| totalCount | `int` | Yes |
| stars | `Map<int, int>` | Yes | `{5: 10, 4: 3, 3: 1, 2: 0, 1: 0}` |

```dart
@JsonSerializable()
class RatingBreakdown {
  final double average;
  final int totalCount;
  final Map<int, int> stars;
}
```

---

## 14. Return

**Backend table:** `returns` + `return_items`

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | |
| returnNumber | `String` | Yes | |
| orderId | `int` | Yes | Original order |
| invoiceNumber | `String` | Yes | Original invoice |
| sellerName | `String` | Yes | |
| status | `ReturnStatus` | Yes | pending, approved, rejected, completed |
| reason | `String` | Yes | |
| description | `String?` | No | |
| refundAmount | `double?` | No | Set on approval |
| rejectionReason | `String?` | No | Set on rejection |
| items | `List<ReturnItem>` | Yes | |
| createdAt | `DateTime` | Yes | |

```dart
enum ReturnStatus { pending, approved, rejected, completed }

@JsonSerializable()
class ReturnModel {
  final int id;
  final String returnNumber;
  final int orderId;
  final String invoiceNumber;
  final String sellerName;
  final ReturnStatus status;
  final String reason;
  final String? description;
  final double? refundAmount;
  final String? rejectionReason;
  final List<ReturnItem> items;
  final DateTime createdAt;
}
```

---

## 15. Notification

**Backend table:** New (to be created for mobile push)

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | |
| type | `NotificationType` | Yes | order_status, return_update, promotion, support_reply |
| title | `String` | Yes | Push title |
| body | `String` | Yes | Push body |
| data | `Map<String, dynamic>?` | No | Navigation payload |
| read | `bool` | Yes | Read state |
| createdAt | `DateTime` | Yes | |

```dart
enum NotificationType { orderStatus, returnUpdate, promotion, supportReply }

@JsonSerializable()
class NotificationModel {
  final int id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;
}
```

---

## 16. Coupon Result

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| valid | `bool` | Yes | |
| code | `String` | Yes | |
| discountAmount | `double?` | No | Calculated discount |
| discountType | `String?` | No | 'fixed' or 'percentage' |
| message | `String?` | No | Success/error message |

```dart
@JsonSerializable()
class CouponResult {
  final bool valid;
  final String code;
  final double? discountAmount;
  final String? discountType;
  final String? message;
}
```

---

## 17. Support Ticket

**Backend table:** `support_tickets` (from SupportController)

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | |
| subject | `String` | Yes | |
| status | `String` | Yes | open, waiting, resolved, closed |
| category | `String` | Yes | order, general, technical |
| orderId | `int?` | No | Related order |
| lastMessageAt | `DateTime?` | No | |
| createdAt | `DateTime` | Yes | |

### TicketMessage

| Field | Dart Type | Required | Notes |
|-------|-----------|----------|-------|
| id | `int` | Yes | |
| body | `String` | Yes | Message content |
| sender | `String` | Yes | 'buyer' or 'agent' |
| createdAt | `DateTime` | Yes | |

```dart
@JsonSerializable()
class TicketModel {
  final int id;
  final String subject;
  final String status;
  final String category;
  final int? orderId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
}

@JsonSerializable()
class TicketMessage {
  final int id;
  final String body;
  final String sender;
  final DateTime createdAt;
}
```

---

## Model Relationships

```
UserModel
  ├── has many → OrderModel
  ├── has many → AddressModel
  ├── has many → WishlistItem (ProductModel reference)
  ├── has many → ReviewModel
  ├── has many → ReturnModel
  └── has many → TicketModel

OrderModel
  ├── has many → OrderItem
  ├── has many → OrderTimelineEntry
  └── may have → ReturnModel

ProductModel (list) → extends to → ProductDetailModel (detail)
  ├── has many → VariantModel
  ├── has many → ReviewModel
  ├── belongs to → SellerModel (via sellerId)
  └── belongs to → CategoryModel

CartItem → references → ProductModel (via productId)

SellerModel
  ├── has many → ProductModel
  └── has many → StoreRating
```
