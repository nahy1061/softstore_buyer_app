# Backend Team Requirements

## Overview

The Flutter buyer app requires JSON API endpoints. The current backend serves HTML pages. The backend team must create `/api/` routes that return JSON for mobile consumption.

**Recommended approach:** Backend exempts `/api/*` routes from CSRF (session cookie is sufficient protection). All endpoints return the standard JSON envelope:

```json
{"success": true, "data": {...}, "message": "..."}
{"success": false, "message": "...", "errors": {"field": ["..."]}}
```

---

## Priority 1 — Blocking (Needed Week 1-2)

These must exist before the mobile team can integrate real data.

| # | Endpoint | Method | Purpose | Request | Response | Blocking |
|---|----------|--------|---------|---------|----------|----------|
| 1 | `/api/buyer/login` | POST | Buyer login | `{email, password, captcha_token}` | `{user: {...}}` + Set-Cookie | YES — blocks all auth |
| 2 | `/api/buyer/register` | POST | Buyer registration | `{full_name, email, phone?, password, captcha_token}` | `{user, otp_sent: true}` + Set-Cookie | YES |
| 3 | `/api/buyer/auth/google` | POST | Google OAuth | `{id_token}` | `{user, is_new_account}` + Set-Cookie | YES |
| 4 | `/api/buyer/verify-email` | POST | Verify email OTP | `{otp_code}` | `{email_verified: true}` | YES |
| 5 | `/api/buyer/me` | GET | Check session | — | `{user: {...}}` or 401 | YES — session validation |
| 6 | `/api/buyer/logout` | POST | Destroy session | — | `{success}` | YES |
| 7 | `/api/store/products` | GET | Product list | `?page=&per_page=&category=&search=&sort=&min_price=&max_price=` | `{products: [...], meta: {total, pages}}` | YES — blocks home screen |
| 8 | `/api/store/products/{slug}` | GET | Product detail | — | `{product, pricing, gallery, variants, reviews, seller, ...}` | YES — blocks detail |
| 9 | `/api/store/categories` | GET | Category list | — | `{categories: [{id, name, slug, product_count}]}` | YES |

---

## Priority 2 — High (Needed Week 2-3)

| # | Endpoint | Method | Purpose | Request | Response | Blocking |
|---|----------|--------|---------|---------|----------|----------|
| 10 | `/api/store/search-suggest` | GET | Search autocomplete | `?q=` | `{suggestions: [...]}` | Partial (exists on web) |
| 11 | `/api/store/cart/validate-item` | POST | Validate cart item | `{product_id, variant_id?, quantity}` | `{valid, available_stock, current_price}` | YES — cart validation |
| 12 | `/api/store/cart/age-check` | POST | Age restriction check | `{product_ids: [...]}` | `{age_restricted: [...]}` | YES |
| 13 | `/api/buyer/wishlist` | GET | Get wishlist | — | `{items: [...]}` | YES |
| 14 | `/api/buyer/wishlist/toggle` | POST | Toggle wishlist | `{product_id}` | `{is_wishlisted: bool}` | YES |
| 15 | `/api/buyer/profile` | GET | Get profile | — | `{user: {id, first_name, last_name, email, phone, ...}}` | YES |
| 16 | `PUT /api/buyer/profile` | PUT | Update profile | `{first_name, last_name, phone}` | `{user: {...}}` | YES |
| 17 | `/api/buyer/addresses` | GET | List addresses | — | `{addresses: [...]}` | YES — blocks checkout |
| 18 | `/api/buyer/addresses` | POST | Add address | `{recipient_name, phone, address_line1, ...}` | `{address: {...}}` | YES |
| 19 | `PUT /api/buyer/addresses/{id}` | PUT | Update address | Same as add | `{address: {...}}` | YES |
| 20 | `DELETE /api/buyer/addresses/{id}` | DELETE | Delete address | — | `{success}` | YES |
| 21 | `/api/store/sellers/{slug}` | GET | Seller store page | `?page=&category=&sort=` | `{seller: {...}, products: [...]}` | YES |

---

## Priority 3 — Medium (Needed Week 3-4)

| # | Endpoint | Method | Purpose | Request | Response | Blocking |
|---|----------|--------|---------|---------|----------|----------|
| 22 | `/api/store/checkout/send-code` | POST | Send OTP email | `{email, name, phone}` | `{success}` | YES — blocks checkout |
| 23 | `/api/store/checkout/verify-code` | POST | Verify checkout OTP | `{code}` | `{verified: true}` | YES |
| 24 | `/api/store/validate-coupon` | POST | Validate coupon | `{code, items: [...]}` | `{valid, discount_amount, discount_type}` | YES |
| 25 | `/api/store/checkout` | POST | Place order | `{customer_*, items, coupon_code?, notes?}` | `{invoice_number, order_ref}` | YES — core feature |
| 26 | `/api/store/order-confirmation/{ref}` | GET | Order confirmation | — | `{order_ref, sub_orders: [...]}` | YES |
| 27 | `/api/buyer/orders` | GET | Order history | `?page=&status=` | `{orders: [...], meta: {...}}` | YES |
| 28 | `/api/buyer/orders/{id}` | GET | Order detail | — | `{order: {items, timeline, totals, ...}}` | YES |
| 29 | `/api/store/track-order` | GET | Public tracking | `?invoice=&phone=` | `{order: {status, items, timeline}}` | YES |
| 30 | `/api/buyer/change-password` | POST | Change password | `{current_password, new_password, confirmation}` | `{success}` | YES |
| 31 | `/api/buyer/forgot-password` | POST | Request reset | `{email}` | `{success, message}` | YES |
| 32 | `/api/buyer/reset-password` | POST | Reset password | `{token, password, confirmation}` | `{success}` | YES |

---

## Priority 4 — Lower (Needed Week 4-5)

| # | Endpoint | Method | Purpose | Request | Response | Blocking |
|---|----------|--------|---------|---------|----------|----------|
| 33 | `/api/buyer/orders/{id}/cancel` | POST | Cancel order | `{reason?}` | `{success}` or error | No |
| 34 | `/api/buyer/orders/{id}/return` | POST | Submit return | `{items, description?, evidence_urls?}` | `{return_number}` | No |
| 35 | `/api/buyer/returns` | GET | List returns | — | `{returns: [...]}` | No |
| 36 | `/api/buyer/returns/upload-evidence` | POST | Upload image | multipart/form-data | `{url}` | No |
| 37 | `/api/buyer/notifications/register-device` | POST | Register FCM | `{fcm_token, platform}` | `{success}` | No |
| 38 | `/api/buyer/notifications` | GET | List notifications | `?page=` | `{notifications: [...], unread_count}` | No |
| 39 | `/api/buyer/notifications/{id}/read` | POST | Mark read | — | `{success}` | No |
| 40 | `/api/buyer/notifications/read-all` | POST | Mark all read | — | `{success}` | No |
| 41 | `/api/buyer/support/tickets` | POST | Create ticket | `{subject, message, order_id?, category}` | `{ticket: {...}}` | No |
| 42 | `/api/buyer/support/tickets` | GET | List tickets | — | `{tickets: [...]}` | No |
| 43 | `/api/buyer/support/tickets/{id}/messages` | GET | Get messages | `?since=` | `{messages: [...]}` | No |
| 44 | `/api/buyer/support/tickets/{id}/messages` | POST | Send message | `{body}` | `{message: {...}}` | No |
| 45 | `/api/store/sellers/{slug}/follow` | POST | Follow store | — | `{is_following: true}` | No |
| 46 | `/api/store/sellers/{slug}/unfollow` | POST | Unfollow store | — | `{is_following: false}` | No |
| 47 | `/api/store/sellers/{slug}/rate` | POST | Rate store | `{rating, comment?}` | `{new_average}` | No |
| 48 | `/api/buyer/resend-otp` | POST | Resend email OTP | — | `{success}` | No |
| 49 | `/api/store/parcel/{token}` | GET | Parcel tracking | — | `{order: {...}}` | No |
| 50 | `/api/store/cart/validate` | POST | Bulk cart validate | `{items: [...]}` | `{valid, invalid_items, repriced_items}` | No |

---

## Backend Configuration Requirements

| Requirement | Why | Priority |
|-------------|-----|----------|
| Exempt `/api/*` from CSRF | Mobile uses session cookie; CSRF tokens are web-only pattern | P1 |
| Return JSON (not HTML) for all `/api/*` routes | Mobile cannot parse HTML | P1 |
| Support `Accept: application/json` header | Distinguish mobile from web requests | P1 |
| Session cookie name: `SOFTSTORE_SESSID` | Already in use by seller app | P1 |
| Session expiry: 8 hours (current) | Keep consistent | P1 |
| Rate limiting with `retry_after` in response | Mobile shows countdown | P2 |
| Pagination with `meta` object | `{current_page, total_pages, total, per_page}` | P1 |
| Validation errors as field map | `{errors: {email: ["required"], phone: ["invalid"]}}` | P1 |
| FCM server-side integration | Send push notifications on order status change | P3 |
| Image URLs as full paths (not relative) | Mobile needs absolute URLs for `CachedNetworkImage` | P1 |

---

## Timeline Alignment

| Backend Deadline | Mobile Needs |
|-----------------|-------------|
| End of Week 1 | Endpoints #1-9 (auth + products) |
| End of Week 2 | Endpoints #10-21 (wishlist, profile, addresses, seller) |
| End of Week 3 | Endpoints #22-32 (checkout, orders, password) |
| End of Week 4 | Endpoints #33-50 (returns, notifications, support) |

**If backend is delayed:** Mobile team builds with mock data. No idle time. Real integration happens when APIs are ready — the architecture supports hot-swapping mock → real repos.

---

## Questions for Backend Team

1. Will `/api/*` routes be exempt from CSRF? (Recommended: yes)
2. Are product image URLs returned as absolute paths or relative? (Need: absolute)
3. What's the rate limit on login/register? (Need: number + retry_after seconds)
4. Will the coupon validation endpoint check per-item applicability or whole-cart? (Need: per-item)
5. Will order cancellation be allowed for all statuses before "shipped"? (Need: confirmation)
6. Will push notifications use FCM or a different provider? (Assumed: FCM)
7. Is there a staging environment we can test against? (Need: URL + test accounts)
