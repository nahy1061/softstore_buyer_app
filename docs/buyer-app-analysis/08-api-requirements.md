# Phase 3: API Requirements

## Overview

The Softstore backend is a session-based PHP web app. Authentication uses a `SOFTSTORE_SESSID` cookie (not JWT). Every mutating POST requires a `_csrf_token` field. The backend team has confirmed they will add JSON API routes for the buyer mobile app.

This document distinguishes:
- **EXISTING** — Confirmed endpoints from source code analysis
- **PROPOSED** — New endpoints needed for mobile-optimal experience

---

## Authentication

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| Login | POST | `/login` (form, returns HTML redirect) | `/api/buyer/login` | `{email, password, captcha_token}` | `{success, user: {id, name, email, phone, email_verified}}` | No |
| Register | POST | `/register` (form, returns HTML) | `/api/buyer/register` | `{full_name, email, phone?, password, captcha_token}` | `{success, user: {id, name, email}, otp_sent: true}` | No |
| Google OAuth | GET | `/auth/google/buyer/redirect` | `/api/buyer/auth/google` | `{id_token}` (from Google Sign-In SDK) | `{success, user, is_new_account}` | No |
| Logout | POST | `/logout` (CSRF) | `/api/buyer/logout` | `{}` | `{success}` | Yes |
| Verify email OTP | POST | — (embedded in registration flow) | `/api/buyer/verify-email` | `{otp_code}` | `{success, email_verified: true}` | Yes |
| Resend email OTP | POST | `/resend-otp` | `/api/buyer/resend-otp` | `{}` | `{success}` | Yes |
| Forgot password | POST | — (not built for buyers) | `/api/buyer/forgot-password` | `{email}` | `{success, message}` | No |
| Reset password | POST | — (not built for buyers) | `/api/buyer/reset-password` | `{token, password, password_confirmation}` | `{success}` | No |
| Check session | GET | — | `/api/buyer/me` | — | `{user: {...}}` or `401` | Yes |
| CSRF token | GET | — (scraped from HTML) | `/api/csrf-token` | — | `{token}` | No |

---

## Products & Browsing

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request/Params | Response | Auth |
|---------|--------|-------------------|-------------------|----------------|----------|------|
| Product list | GET | `/store` (HTML) | `/api/store/products` | `?page=&per_page=&category=&search=&sort=&min_price=&max_price=&free_del=` | `{products: [...], total, current_page, total_pages, categories: [...]}` | No |
| Product detail | GET | `/product/{slug}` or `/store/product/{id}` (HTML) | `/api/store/products/{slug}` | — | `{product, pricing, gallery, variants, reviews, rating_breakdown, related_products, available_stock, seller, whatsapp_url}` | No |
| Categories | GET | Bundled in `/store` response | `/api/store/categories` | — | `{categories: [{id, name, slug, product_count}]}` | No |
| Search suggestions | GET | `/api/store/search-suggest` | `/api/store/search-suggest` | `?q=` | `{suggestions: [{name, slug, type}]}` | No |
| Product by ID | GET | `/store/product/{id}` (301 redirect) | `/api/store/products/id/{id}` | — | Same as product detail | No |

---

## Sellers

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request/Params | Response | Auth |
|---------|--------|-------------------|-------------------|----------------|----------|------|
| Seller store | GET | `/store/{slug}` (HTML) | `/api/store/sellers/{slug}` | `?page=&category=&search=&sort=` | `{seller: {name, slug, rating, city, ...}, products: [...], categories: [...], total_pages}` | No |
| Follow store | POST | `/store/follow` (CSRF) | `/api/store/sellers/{slug}/follow` | `{}` | `{success, is_following: true}` | Yes |
| Unfollow store | POST | `/store/unfollow` (CSRF) | `/api/store/sellers/{slug}/unfollow` | `{}` | `{success, is_following: false}` | Yes |
| Rate store | POST | `/store/{slug}/rate` (CSRF) | `/api/store/sellers/{slug}/rate` | `{rating: 1-5, comment?}` | `{success, new_average}` | Yes |

---

## Cart

Cart is stored in local storage on the mobile app. These endpoints validate server-side state.

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| Add to cart (validate) | POST | `/api/store/cart/add` | `/api/store/cart/validate-item` | `{product_id, variant_id?, quantity}` | `{valid, available_stock, current_price, product_name, image_url}` | No |
| Age check | POST | `/api/store/cart-age-check` | `/api/store/cart/age-check` | `{product_ids: [...]}` | `{age_restricted: [{product_id, product_name}]}` | No |
| Validate cart (pre-checkout) | POST | — | `/api/store/cart/validate` | `{items: [{product_id, variant_id?, quantity}]}` | `{valid, invalid_items: [{product_id, reason}], repriced_items: [{product_id, old_price, new_price}]}` | No |

---

## Wishlist

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| Get wishlist | GET | `/marketplace/account/wishlist` (HTML) | `/api/buyer/wishlist` | — | `{items: [{product_id, product_name, price, image_url, in_stock}]}` | Yes |
| Toggle wishlist | POST | `/api/marketplace/wishlist/toggle` | `/api/buyer/wishlist/toggle` | `{product_id}` | `{success, is_wishlisted: true/false}` | Yes |
| Check if wishlisted | GET | — | `/api/buyer/wishlist/check` | `?product_ids=1,2,3` | `{wishlisted: [1, 3]}` | Yes |

---

## Addresses

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| List addresses | GET | `/marketplace/account/addresses` (HTML) | `/api/buyer/addresses` | — | `{addresses: [{id, label, recipient_name, phone, address_line1, address_line2, city, state, postal_code, is_default}]}` | Yes |
| Add address | POST | `/marketplace/account/addresses` (form) | `/api/buyer/addresses` | `{recipient_name, phone, address_line1, address_line2?, city, state?, postal_code?, is_default?}` | `{success, address: {...}}` | Yes |
| Update address | PUT | — | `/api/buyer/addresses/{id}` | Same as add | `{success, address: {...}}` | Yes |
| Delete address | POST | `/marketplace/account/addresses/{id}/delete` | `DELETE /api/buyer/addresses/{id}` | — | `{success}` | Yes |
| Set default | PUT | — | `/api/buyer/addresses/{id}/default` | `{}` | `{success}` | Yes |

---

## Checkout

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| Send OTP | POST | `/store/checkout/send-code` | `/api/store/checkout/send-code` | `{email, name, phone}` | `{success, message}` | No |
| Verify OTP | POST | `/store/checkout/verify-code` | `/api/store/checkout/verify-code` | `{code}` | `{success, verified: true}` | No |
| Validate coupon | POST | `/api/store/validate-coupon` | `/api/store/validate-coupon` | `{code, items: [{id, qty, variant_id?}]}` | `{valid, discount_amount, discount_type, message}` | No |
| Place order | POST | `/store/checkout` (CSRF) | `/api/store/checkout` | `{customer_name, customer_phone, customer_address, customer_city, customer_email, payment_method: 'cod', notes?, coupon_code?, items: [{id, qty, variant_id?}]}` | `{success, invoice_number, order_ref}` | No* |
| Get recommendations | POST | `/api/store/checkout/recommendations` | `/api/store/checkout/recommendations` | `{items: [{id, qty, variant_id?}]}` | `{recommendations: [{product_id, name, price, reason}]}` | No |

*Place order works for guests (email OTP verified) and logged-in users.

---

## Orders

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request/Params | Response | Auth |
|---------|--------|-------------------|-------------------|----------------|----------|------|
| Order history | GET | `/marketplace/account/orders` (HTML) | `/api/buyer/orders` | `?page=&status=` | `{orders: [{id, invoice_number, status, grand_total, items_count, seller_name, created_at}], total_pages}` | Yes |
| Order detail | GET | `/marketplace/account/orders/{id}` (HTML) | `/api/buyer/orders/{id}` | — | `{order: {invoice, status, items: [...], timeline: [...], totals, delivery, seller, return_eligible}}` | Yes |
| Public tracking | GET | `/track-order?invoice=&phone=` (HTML) | `/api/store/track-order` | `?invoice=&phone=` | `{order: {invoice, status, items, timeline, seller, delivery_address}}` | No |
| Order confirmation | GET | `/store/order-confirmation` (HTML) | `/api/store/order-confirmation/{ref}` | — | `{order_ref, sub_orders: [{seller_name, items, subtotal, tax, delivery_fee, total, status}]}` | No |
| Cancel order | POST | — (not built) | `/api/buyer/orders/{id}/cancel` | `{reason?}` | `{success}` or `{error: "already_processing"}` | Yes |

---

## Returns

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| List returns | GET | `/marketplace/account/returns` (HTML) | `/api/buyer/returns` | — | `{returns: [{id, return_number, invoice, seller, amount, status, reason, created_at}]}` | Yes |
| Submit return | POST | `/marketplace/account/orders/{id}/return` (form) | `/api/buyer/orders/{id}/return` | `{items: [{product_id, quantity, reason}], description?, evidence_urls?: [...]}` | `{success, return_number}` | Yes |
| Upload evidence | POST | — | `/api/buyer/returns/upload-evidence` | `multipart/form-data` (image/video) | `{url}` | Yes |

---

## Reviews

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| Submit review | POST | `/marketplace/account/reviews` (CSRF) | `/api/buyer/reviews` | `{product_id, order_id, rating, title?, comment}` | `{success, review_id}` | Yes |
| Get product reviews | GET | Bundled in product detail | `/api/store/products/{slug}/reviews` | `?page=` | `{reviews: [...], rating_breakdown, total}` | No |

---

## Profile

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| Get profile | GET | `/marketplace/account/profile` (HTML) | `/api/buyer/profile` | — | `{user: {id, first_name, last_name, email, phone, email_verified, created_at}}` | Yes |
| Update profile | POST | `/marketplace/account/profile` (form) | `PUT /api/buyer/profile` | `{first_name, last_name, phone}` | `{success, user}` | Yes |
| Change password | POST | — | `/api/buyer/change-password` | `{current_password, new_password, new_password_confirmation}` | `{success}` | Yes |
| Dashboard stats | GET | `/marketplace/account` (HTML) | `/api/buyer/dashboard` | — | `{total_orders, total_spent, wishlist_count, recent_orders: [...]}` | Yes |

---

## Notifications

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| Register FCM token | POST | — | `/api/buyer/notifications/register-device` | `{fcm_token, platform: 'android'/'ios'}` | `{success}` | Yes |
| List notifications | GET | — | `/api/buyer/notifications` | `?page=` | `{notifications: [{id, type, title, body, data, read, created_at}], unread_count}` | Yes |
| Mark read | POST | — | `/api/buyer/notifications/{id}/read` | `{}` | `{success}` | Yes |
| Mark all read | POST | — | `/api/buyer/notifications/read-all` | `{}` | `{success}` | Yes |

---

## Support

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request Body | Response | Auth |
|---------|--------|-------------------|-------------------|-------------|----------|------|
| Create ticket | POST | `/support/new` (form) | `/api/buyer/support/tickets` | `{subject, message, order_id?, category}` | `{success, ticket: {id, ...}}` | Yes |
| List tickets | GET | — | `/api/buyer/support/tickets` | — | `{tickets: [{id, subject, status, last_message_at}]}` | Yes |
| Get messages | GET | `/support/ticket/{id}/messages` (long-poll) | `/api/buyer/support/tickets/{id}/messages` | `?since=` | `{messages: [{id, body, sender, created_at}]}` | Yes |
| Send message | POST | — | `/api/buyer/support/tickets/{id}/messages` | `{body}` | `{success, message}` | Yes |

---

## Parcel Tracking

| Feature | Method | Existing Endpoint | Proposed Endpoint | Request/Params | Response | Auth |
|---------|--------|-------------------|-------------------|----------------|----------|------|
| Parcel by QR token | GET | `/parcel/{token}` (HTML) | `/api/store/parcel/{token}` | — | `{order: {invoice, status, items, delivery_address, seller}}` | No |

---

## API Design Notes

### Base URL
```
https://softstore.pk/api/
```

### Authentication Pattern
All `Auth: Yes` endpoints require the `SOFTSTORE_SESSID` cookie. The mobile app maintains this cookie via Dio's cookie jar. If the session expires, the API returns `401` and the app redirects to login.

### CSRF Handling
For the proposed JSON API routes, CSRF can be handled via:
- Option A: Backend exempts `/api/*` routes from CSRF (since they require session cookie already)
- Option B: App fetches CSRF token from `/api/csrf-token` and includes as `X-CSRF-TOKEN` header

Recommendation: **Option A** (simpler, standard practice for API routes).

### Response Format (Standard Envelope)
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional human-readable message"
}

// Error:
{
  "success": false,
  "message": "What went wrong",
  "errors": {
    "email": ["The email field is required"],
    "phone": ["Invalid phone format"]
  }
}
```

### Pagination Format
```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total": 47,
    "per_page": 12
  }
}
```

### Rate Limiting
Endpoints that are rate-limited return `429 Too Many Requests` with:
```json
{
  "success": false,
  "message": "Too many attempts. Please try again later.",
  "retry_after": 60
}
```

Rate-limited endpoints: login, register, send-code, place-order, forgot-password.
