# Monetization, Play Billing, and Ads
How Android apps earn money the way Google Play requires: through the Play Billing Library for digital goods, with clear rules for subscriptions and one-time purchases, proper testing, and careful use of ads. When a deadline or policy here matters to a release, check the official page linked nearby — these dates move.
## The core rule: digital goods use Play billing
Apps distributed on Google Play must use **Google Play's billing system** for purchases of digital goods and services sold inside the app, including:
- Premium features and unlocked content
- In-game currency and items
- Subscriptions (media, fitness, productivity, dating, and more)
- Cloud storage, ad removal, and digital media
Physical goods and real-world services (ride hailing, food delivery, store merchandise, in-person services) do **not** use Play billing — they use a normal payment method.
Do not add your own card form, a web checkout link, or buttons that steer users to pay outside the app for digital goods. That is the most common billing policy violation.
Policy: https://support.google.com/googleplay/android-developer/answer/10281818 and https://play.google.com/about/monetization-ads/payments/
## Regional exceptions and alternative billing
The rule has real exceptions, and they change by country:
- In some regions, eligible apps may offer an **alternative billing system** alongside or instead of Play billing, under programs such as User Choice Billing or specific regulatory settlements (for example in South Korea, India, the EEA, and under recent US court-ordered changes).
- Each program has enrollment, reporting, and service-fee terms. Alternative billing is never just "add another payment provider and ship."
- Reader apps (books, music, news) have a separate set of rules for linking out to purchases on the web.
If you plan to use any exception, enroll in the exact program in Play Console and follow its declaration steps before release: https://developer.android.com/google/play/billing/alternative
## Play Billing Library version requirements
Google requires apps to use a recent Play Billing Library (PBL). Old versions stop being accepted for new apps and updates.
**Plan for these dates:**
- The **version 7 deadline has passed** — updates still on PBL 6 or older can no longer be submitted as before.
- **From November 2026**, new apps and app updates must use **Play Billing Library version 8 or higher**. Build the upgrade into your schedule well before November; do not wait for a Play Console rejection to start.
Always confirm the current requirement before a release: https://developer.android.com/google/play/billing/release-notes and https://support.google.com/googleplay/android-developer/answer/12154973
Add the library in `build.gradle.kts` (use the highest 8.x patch available when you build):
```kotlin
dependencies {
    implementation("com.android.billingclient:billing:8.0.0")
    implementation("com.android.billingclient:billing-ktx:8.0.0")
}
```
## What changed in Billing Library 8
Version 8 removed some old APIs. The one that breaks the most code:
- **`queryPurchaseHistory` is removed.** It was deprecated earlier and is gone in v8. Replace history queries with `queryPurchasesAsync`, which returns purchases the user currently owns, and keep your own record of past orders on your server if you need a history view.
- Product and purchase models were tightened — one-time products and subscriptions are modeled more explicitly, and several legacy helpers were removed in favor of the `ProductDetails` APIs introduced in v5 and later.
Migration guide: https://developer.android.com/google/play/billing/migrate-gpblv8
A typical query with current APIs:
```kotlin
val params = QueryProductDetailsParams.newBuilder()
    .setProductList(listOf(
        QueryProductDetailsParams.Product.newBuilder()
            .setProductId("premium_monthly")
            .setProductType(BillingClient.ProductType.SUBS)
            .build()
    )).build()
billingClient.queryProductDetailsAsync(params) { result, details ->
    if (result.responseCode == BillingClient.BillingResponseCode.OK) {
        // Show details.productDetailsList to the user
    }
}
```
## One-time products and subscriptions
**One-time products** are bought once: a level pack, an e-book, or a permanent unlock. Consumables (like coins) can be bought again after they are consumed; non-consumables (like "remove ads") stay owned forever.
- Acknowledge every purchase within 3 days or Play refunds it.
- Consume consumables only after granting the item, and grant only once per purchase token.
**Subscriptions** charge on a repeating cycle until cancelled:
- Offer a base plan, and optionally offers with free trials or introductory prices, all configured in Play Console.
- Handle the full lifecycle: new purchase, renewal, grace period (payment failed but access continues for a short time), account hold (access paused), cancellation (access until period end), and expiry.
- Users manage and cancel subscriptions in Google Play, not only in your app. Link to the Play subscriptions screen from your settings.
- Verify subscription state on your server with the Play Developer API for anything valuable — client state can be stale or tampered with.
Docs: https://developer.android.com/google/play/billing/subscriptions and https://developer.android.com/google/play/billing/lifecycle
Minimal purchase launch in Kotlin:
```kotlin
val flowParams = BillingFlowParams.newBuilder()
    .setProductDetailsParamsList(listOf(
        BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(details)
            // .setOfferToken(offerToken) // required for subscriptions with offers
            .build()
    )).build()
billingClient.launchBillingFlow(activity, flowParams)
```
Always listen in `PurchasesUpdatedListener`, verify the purchase, grant the entitlement, then acknowledge (and consume if needed).
## Testing with license testers
Never test real purchases with real money. Play gives you a full test setup:
1. In Play Console, add **license testers** under **Settings > License testing** (email addresses or Google Groups).
2. Upload the app to an internal or closed testing track. Billing test flows only work for builds installed from Play.
3. Testers see test payment methods ("Test card, always approves" / "always declines") and are never charged.
4. Test subscriptions renew on a shortened schedule (minutes, not months), so you can test renewal, grace period, and expiry in one sitting.
5. Use the billing testing docs to test error cases as well as success.
Also test: buying twice, restoring on a fresh install, cancelling and re-subscribing, and a purchase on a second device.
See: https://developer.android.com/google/play/billing/test and https://support.google.com/googleplay/android-developer/answer/6062777
## Server verification and security basics
- Verify purchase tokens on your server with the Google Play Developer API before granting valuable entitlements.
- Use Real-time Developer Notifications (RTDN) via Pub/Sub to learn about cancellations, holds, and renewals promptly.
- Never trust a price or entitlement read only on the device.
- Keep product IDs consistent between Play Console, the app, and your server. A typo here fails silently for users.
## Ads basics
Ads are the other common income source, usually through the Google Mobile Ads SDK (AdMob) or a mediation setup.
- Load ads off the main thread, preload sensibly, and never place ads where they cause accidental clicks (next to buttons, over content, or as surprise interstitials on back press).
- Interstitials (full-screen ads) need a clear close button and a natural break point — between levels or articles, not mid-task.
- Label paid and ad content honestly. Deceptive ad behavior is both an AdMob and a Play policy violation.
- Ads SDKs collect data — declare it in your Data safety section and privacy policy (see the release guide in this set).
Docs: https://developers.google.com/admob/android/quick-start and https://play.google.com/about/monetization-ads/ads/
## Consent with the User Messaging Platform (UMP)
In the EEA, UK, and other regulated regions you must gather consent before personalized ads and related data use. Google's **User Messaging Platform (UMP) SDK** is the standard way to do it inside AdMob apps:
```kotlin
val params = ConsentRequestParameters.Builder().build()
val consentInfo = UserMessagingPlatform.getConsentInformation(this)
consentInfo.requestConsentInfoUpdate(this, params,
    {
        UserMessagingPlatform.loadAndShowConsentFormIfRequired(this) { error ->
            if (consentInfo.canRequestAds()) startLoadingAds()
        }
    },
    { error -> /* Log and continue without personalized ads */ }
)
```
- Show the form when required, respect the choice, and provide a way to revisit it (a "Privacy options" entry) where required.
- Do not request ads before consent is resolved where the law requires consent first.
- Test with debug geography overrides, not by travelling.
See: https://developers.google.com/admob/android/privacy
## Families policy caution
If your app targets children, in whole or in part, the rules get much stricter — read them before adding any monetization:
- Only ad SDKs certified for the Families program may serve ads.
- No personalized ads for children; no interstitial tricks, no ads that look like content or gameplay.
- Purchases need parental gates; no pressure tactics aimed at children ("buy now or lose it").
- Mixed-audience apps must use neutral age screens and apply child rules whenever the user is a child.
Declaring the wrong target audience is a common cause of removal. See: https://play.google.com/about/families/ and https://support.google.com/googleplay/android-developer/answer/9893335
## Checklist
1. Digital goods use Play billing; no outside payment steering.
2. Billing Library is version 8 or higher; no `queryPurchaseHistory`.
3. Purchases verified, acknowledged in time, consumables consumed.
4. Subscription lifecycle states handled and tested with testers.
5. License testers configured; shortened renewals tested.
6. Ads placed safely, Data safety updated, UMP consent working.
7. Families rules checked if children are any part of the audience.
## Summary
Use Play billing for digital goods, stay on Billing Library 8 or higher, test with license testers instead of real money, and verify purchases on your server. Use ads carefully, gather consent with UMP where required, and treat Families rules as a hard constraint whenever children are in the audience.
