# RevenueCat and App Store release setup

This checklist accompanies [monetization.md](monetization.md). Do not mark a
release gate complete from a simulator build alone.

## App Store Connect products

Create four **consumable** in-app purchases for bundle
`com.tanercelik.patika`. Use the product identifiers below exactly. US prices
are base prices; let Apple provide the displayed local price.

| Product ID | English display name | English review description | US price |
| --- | --- | --- | ---: |
| `path.unlock.7d` | Continue a 7-day path | Unlock the rest of this 7-day path. | $7.99 |
| `path.unlock.14d` | Continue a 14-day path | Unlock the rest of this 14-day path. | $11.99 |
| `path.unlock.21d` | Continue a 21-day path | Unlock the rest of this 21-day path. | $14.99 |
| `path.unlock.28d` | Continue a 28-day path | Unlock the rest of this 28-day path. | $18.99 |

Review notes: the first personal session is free. Complete it and pass the G2
summary to see the paywall. A visible **Not now** exits immediately. Purchases
are one-time and path-specific. Prepared paths and Destek al remain free.
Include screenshots of G2, the paywall with local price, Yolum before and
after a purchase, and the restore/help route.

Shipaton materials include a 1024 × 1024 app icon, at least one 1179 × 2556
frameless screenshot, a public YouTube or Vimeo demo (the core experience in
its first two minutes), the RevenueCat project ID, and a working free reviewer
grant. A standard entry requires a live US App Store listing; TestFlight alone
does not qualify.

Connect the App Store in RevenueCat using Apple's in-app purchase key. Configure
App Store Server Notifications so refunds of one-time purchases are reported
promptly. The initial IAPs must be submitted with the app for review.

## RevenueCat dashboard

1. Create an iOS app in the Patika project with the same bundle ID.
2. Import the four products. Create `path_7d`, `path_14d`, `path_21d`,
   `path_28d`; attach exactly one matching package to each offering. Do not
   attach a global premium entitlement to consumables.
3. Make one editor paywall per offering, using the same design and
   [forest illustration](../assets/illustrations/paywall/forest-path-after-first-step.png).
   Upper illustration; flat dark text area; cream purchase button. Configure
   the button with the package's localized StoreKit price. Expose close,
   **Not now**, **Restore purchases**, and legal/support links at first display.
4. Use only `path_days` and `remaining_sessions` custom variables.
5. Add a signed webhook pointing at
   `https://aapxqeqduphafisyaadk.supabase.co/functions/v1/revenuecat-webhook`.
   Deliver non-renewing purchase, cancellation and refund-reversed events.
6. Put the **public** iOS SDK key into the Xcode
   `REVENUECAT_IOS_API_KEY` build setting for the release configuration.
   Put `REVENUECAT_PROJECT_ID`, `REVENUECAT_SECRET_API_KEY` and
   `REVENUECAT_WEBHOOK_SIGNING_SECRET` in Supabase Edge Function secrets.
   For timed Shipaton promotional access also set
   `REVENUECAT_V1_SECRET_API_KEY`.
   The last two are server-only; never add them to Xcode or this repository.

The webhook requires its RevenueCat HMAC signature and confirms the StoreKit
transaction with the RevenueCat v2 purchases API. It must be deployed with
Supabase platform JWT verification **off** because RevenueCat does not send a
Supabase user JWT; the handler performs its own signature verification.
`path-purchase-intent` and `path-purchase-status` require user JWTs.

## Shipaton review access

Create a separate `shipaton_review` RevenueCat promotional entitlement and a
dedicated reviewer customer. Grant it for a **fixed expiry after the reviewer
finishes the first session**. RevenueCat sends promotional grants as production
`NON_RENEWING_PURCHASE` events with store `PROMOTIONAL`. The signed webhook
checks that the same customer has an active timed entitlement through the
RevenueCat v1 subscriber API, then writes an expiring path-specific grant.
Exercise this route before submitting reviewer credentials; do not give the
jury a client-only bypass. Record the reviewer path and expiry, and remove
access after review.

## End-to-end checks

For each length: offering and local price, first completed G2, Not now, later
Yolum purchase, successful purchase, pending payment, cancellation, offline
return, repeated callback, duplicate webhook, refund and refund reversal.
Verify a direct request for unpaid day 2 audio, manifest, signed URL and
completion is denied. Verify day 1 replay, prepared paths, Destek al and
crisis support still work. Compare sandbox price metadata with the StoreKit
purchase sheet's storefront. Finish with Apple sandbox on a real device.
