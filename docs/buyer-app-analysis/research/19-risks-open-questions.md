# Phase 4: Risks & Open Questions

## Technical Risks

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| T1 | **Backend JSON API not ready on time** — Flutter team blocked waiting for endpoints | High | High | Backend starts `/api/buyer/*` routes in parallel from Week 1. Flutter uses mock JSON fixtures until endpoints are live. Define API contract (request/response format) in Week 1 and freeze. | Backend Lead |
| T2 | **Session cookie approach fragile on mobile** — cookie jar bugs, platform differences | Medium | High | Tested approach (seller RN app uses same pattern). Use `dio_cookie_manager` with file-backed jar. Test on both platforms early in Phase 0. | Dev B |
| T3 | **reCAPTCHA invisible widget unreliable on Flutter** — native bridge issues | Medium | Medium | Test in Phase 0 spike. Fallback: backend exempts mobile API routes from captcha (use device attestation instead). | Dev C |
| T4 | **Image loading slow on Pakistani networks** — large product images | High | Medium | Request thumbnails for grids (max 400px width). Use `cached_network_image` with placeholder. Propose image resizing endpoint to backend. | Dev A |
| T5 | **State management complexity grows** — Cubits proliferate, cross-feature state hard to track | Low | Medium | Strict rules: only 4 global Cubits. Feature Cubits are scoped to routes. No "god Cubit" allowed. Code review enforces. | All |
| T6 | **Deep linking conflicts with GoRouter** — edge cases with auth guards + deep links | Medium | Low | Handle in Phase 1 (Dev A). Test: cold start deep link to protected route → login → redirect. Known GoRouter pattern. | Dev A |
| T7 | **Offline cart diverges from server prices** — buyer adds at Rs 500, price changes to Rs 600 before checkout | Medium | Medium | Cart validation endpoint (`POST /api/store/cart/validate`) called before checkout. Shows repriced items to buyer with option to continue or remove. | Dev B |

## Backend Risks

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| B1 | **Stock drift bug (B1 from buyer doc)** — inventory inconsistency | Known | Medium | App relies on server-side stock validation at checkout. App never trusts local stock data for final order. Backend must fix the drift for accuracy of displayed stock on product cards. | Backend |
| B2 | **No buyer password reset exists yet** — bug B3 in buyer doc | Known | Medium | Must be built before app launch. Simple flow: email + token + reset form. If delayed, hide "Forgot password" in app and show "Contact support" instead. | Backend |
| B3 | **Session timeout too short (8h)** — buyer loses session overnight | Medium | Low | App handles gracefully: 401 → re-login. UX impact is minimal since cart is local. Longer sessions or "remember me" would improve experience. | Backend |
| B4 | **Rate limiting may be too aggressive** — sellers and buyers share throttle config | Low | Medium | Backend should configure separate rate limits for `/api/buyer/*` routes. If not, app shows countdown timer and graceful message. | Backend |
| B5 | **Multi-seller order splitting not exposed in current API** — order confirmation shows sub-orders but no explicit API | Medium | Low | Propose: `/api/store/order-confirmation/{ref}` returns sub-orders array. If not available, show single combined order view. | Backend |

## Authentication Risks

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| A1 | **Google OAuth redirect URI misconfigured** — doc notes it must be set in .env | Medium | Medium | Verify OAuth config with backend in Week 1. Test on both Android and iOS. Fallback: email/password login always works. | Dev C + Backend |
| A2 | **CSRF required on API routes** — if backend doesn't exempt /api/* | Low | Medium | If required: add CsrfInterceptor that fetches token from `/api/csrf-token`. Architecture supports this (interceptor slot exists). | Dev B |
| A3 | **Session not shared across subdomains** — if API is on api.softstore.pk vs softstore.pk | Low | High | Clarify with backend: same domain or cookie domain set to `.softstore.pk`. Same-origin is simplest. | Backend |

## Performance Risks

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| P1 | **Product grid jank on low-end devices** — too many images loading simultaneously | Medium | Medium | Lazy-load images (viewport only). Limit grid to 2 columns. Use `RepaintBoundary` on cards. Test on budget device (2GB RAM). | Dev A |
| P2 | **Checkout form lag on older Android** — multiple text fields + validation | Low | Low | Debounce validation (300ms). Don't rebuild entire screen on every keystroke. | Dev B |
| P3 | **Large response payloads** — product list returns too much data | Medium | Medium | Propose pagination at 12 items/page. Backend should support `?fields=` for sparse responses. Image URLs should be thumbnail-sized for lists. | Backend |

## Data Risks

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| D1 | **Cart data loss on app update** — SharedPreferences cleared | Very Low | Medium | SharedPreferences survives app updates. Add cart version key — if format changes, migrate gracefully. | Dev B |
| D2 | **Stale cache shows wrong price** — price changed server-side but cache shows old | Medium | Low | Stale-while-revalidate: show cached then refresh. Cart validation before checkout catches discrepancies. | Dev B |
| D3 | **User data retained after logout** — privacy concern | Low | High | Clear secure storage on logout. SharedPreferences: clear user-specific data (profile cache, recent orders) but keep cart and preferences. Audit in security testing. | Dev C |

## Integration Risks

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| I1 | **FCM setup delays** — Firebase project not configured, APNs key not uploaded | Medium | Low | Notifications are Phase 2. Backend can defer FCM integration without blocking MVP launch. App ships without push; adds in OTA update. | Backend + Dev C |
| I2 | **Google Sign-In SDK version conflicts** — platform-specific issues | Low | Low | Pin version. Test on both platforms in Phase 3. Google Sign-In is mature and stable. | Dev C |
| I3 | **WhatsApp deep link format varies by market** — `wa.me` vs `api.whatsapp.com` | Low | Low | Use `url_launcher` with `https://wa.me/{number}`. Works universally. | Dev B |
| I4 | **iOS App Store review rejects** — privacy policy or permission issues | Medium | Medium | Prepare privacy manifest (iOS 17+). Justify camera/photo permission (return evidence). No tracking without consent. | Dev C |

---

## Open Questions by Team

### Questions for Backend Team (Priority: HIGH)

| # | Question | Blocking? | Needed By |
|---|----------|-----------|-----------|
| Q1 | **Will you create `/api/buyer/*` JSON endpoints?** We need a clear API contract (endpoint list, request/response format) by Week 1. The full proposed list is in `08-api-requirements.md`. | YES — blocks all API integration | Week 1 |
| Q2 | **CSRF on API routes — exempt or required?** If exempt (recommended), we skip the interceptor. If required, we need `/api/csrf-token`. | Yes — affects API client setup | Week 1 |
| Q3 | **Cookie domain — same origin or subdomain?** Is the API at `softstore.pk/api/` or `api.softstore.pk`? Affects cookie handling. | Yes — affects Dio config | Week 1 |
| Q4 | **Cart validation endpoint — confirm format.** We'll send `{items: [{product_id, variant_id, quantity}]}` and expect `{valid, invalid_items, repriced_items}`. Is this feasible? | Yes — blocks checkout | Week 3 |
| Q5 | **Buyer password reset timeline.** When will `POST /api/buyer/forgot-password` and `POST /api/buyer/reset-password` be ready? | No (can ship without) | Week 5 |
| Q6 | **Address CRUD — confirm endpoints.** We propose `GET/POST /api/buyer/addresses`, `PUT/DELETE /api/buyer/addresses/{id}`. Confirm or propose alternative. | Yes — blocks address book | Week 4 |
| Q7 | **Order cancellation — will it exist for MVP?** If yes, which statuses allow it? If no, we hide the button. | No (can defer) | Week 7 |
| Q8 | **Image resizing — can we request thumbnails?** Either `?w=400` parameter or separate thumbnail URL field in product response. | No (but affects performance) | Week 2 |
| Q9 | **Search suggest endpoint confirmed?** `GET /api/store/search-suggest?q=` — exists in source code but confirm it returns JSON. | Yes — blocks search | Week 2 |
| Q10 | **Notification infrastructure timeline.** When will FCM integration + device token storage be ready? | No (Phase 2 feature) | Week 8 |

### Questions for Softstore Management (Priority: MEDIUM)

| # | Question | Impact |
|---|----------|--------|
| M1 | **MVP launch target date?** Needed to validate if 11-week plan is feasible. | Sprint planning |
| M2 | **Team size — confirmed 3 Flutter devs?** Roadmap assumes 3. With 2, add ~4 weeks. | Timeline |
| M3 | **Android-only MVP or both platforms?** iOS has additional review timeline. | Release planning |
| M4 | **Will there be a staging/beta environment for testing?** Or do we test against `beta.softstore.pk` directly? | CI/CD setup |
| M5 | **App name on stores — "SoftStore" or "Softstore"?** Needed for store listings. | Branding |
| M6 | **Age-restricted products — how common?** If rare, we can defer the age gate to Phase 2. | Scope decision |
| M7 | **Promotional notifications — who sends them?** Admin panel? Automated? Need to understand triggering mechanism. | Notification design |

### Questions for Seller App Team (Priority: LOW)

| # | Question | Impact |
|---|----------|--------|
| S1 | **Session sharing — does buyer and seller share a cookie jar?** Unlikely (different auth systems) but need to confirm there's no conflict if both apps installed on same device. | Edge case |
| S2 | **API client patterns — anything to share?** Their React Native ApiService is a reference. Any pitfalls they discovered with the session approach? | Development speed |
| S3 | **Store rating from buyer — are they displaying it?** Need to confirm the rating appears correctly on the seller side when submitted from the buyer app. | Feature verification |

### Questions for UI/UX Team (Priority: MEDIUM)

| # | Question | Impact |
|---|----------|--------|
| U1 | **Design system — is there a Figma file for the buyer app?** Or do we implement from the website's design patterns? | UI implementation |
| U2 | **App icon and splash — designed?** Needed for Phase 7 polish. | Store readiness |
| U3 | **Onboarding slides content — who writes copy and selects imagery?** | Phase 7 |
| U4 | **Empty state illustrations — custom or stock?** If custom, need them by Week 4 (cart empty state). | UI quality |
| U5 | **Dark mode — confirmed for Phase 2?** Need to know if we design theme with dark variant in mind or add later. | Theme architecture |
| U6 | **Product card layout — match website exactly or mobile-optimized variation?** | Home screen |
| U7 | **Checkout step indicator — stepper bar or numbered circles?** | Checkout UI |

---

## Risk Summary Matrix

```
                         Impact
                    Low    Medium    High
              ┌────────┬──────────┬────────┐
     High     │        │ T4, P3   │ T1     │
              │        │          │        │
Likelihood    ├────────┼──────────┼────────┤
     Medium   │ T6, I4 │ T2, T7  │ B5, A3 │
              │ P2     │ B1, B3  │        │
              ├────────┼──────────┼────────┤
     Low      │ D1, I3 │ T5, A2  │ D3     │
              │ P1     │ I1, I2  │        │
              └────────┴──────────┴────────┘
```

**Top 3 risks to address immediately:**
1. **T1** — Backend API contract must be agreed in Week 1
2. **T2** — Cookie-based session must be validated on both platforms in Phase 0
3. **B2** — Buyer password reset must be scheduled by backend team
