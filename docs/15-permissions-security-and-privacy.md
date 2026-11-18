# Permissions, Security, and Privacy

Users trust an app with their photos, location, contacts, and files.
Android's permission system, and Google Play's privacy rules, exist
to protect that trust. This guide covers asking for less, asking at
the right moment, protecting data at rest and in transit, and the
Play Console declarations that ship with the code.

## 1. Least privilege, first

- Request only the permissions the current feature needs.
- Prefer system features that need no permission: the photo picker
  for images, the share sheet for sending, app-specific storage for
  your own files, and the document picker for user-chosen files.
- Prefer approximate over precise location, and one-time over
  always, when the feature still works that way.
- Remove permissions the code no longer uses. Check the merged
  manifest — libraries can add permissions you did not ask for, and
  you can remove one with `tools:node="remove"` when it is truly
  unused.
- Never request a bundle of permissions at first launch "just in
  case". Apps that do this get denied, and reviewed badly.

## 2. Runtime permissions: ask at the point of use

Dangerous permissions are granted at runtime. The pattern is always:
explain, ask, handle both answers gracefully.

```kotlin
val requestPermission = rememberLauncherForActivityResult(
    ActivityResultContracts.RequestPermission()
) { granted: Boolean ->
    if (granted) viewModel.startCameraFeature()
    else viewModel.showCameraUnavailableMessage()
}

Button(onClick = {
    // Show a short in-app explanation first, then:
    requestPermission.launch(Manifest.permission.CAMERA)
}) { Text("Take a photo") }
```

Guidance:

- Show the rationale in your own UI before the system dialog when
  `shouldShowRequestPermissionRationale()` is true.
- If the user denies, keep the rest of the app working. Offer the
  feature again later, in context — do not nag on every launch.
- If the user picks "don't ask again", direct them to Settings only
  when they tap a clear "open Settings" action inside the feature.
- Test all three states: granted, denied once, and permanently
  denied. Each needs a different screen.
- Request permissions from an Activity or Fragment context, not from
  a Worker or a background service.

## 3. Partial media access and modern media permissions

On Android 14 (API 34) and later, when a user grants
`READ_MEDIA_IMAGES` or `READ_MEDIA_VIDEO`, they can choose
**selected photos only**. The app then sees only the items chosen,
plus anything it created.

- Handle partial access as a normal state, not an error. Show the
  selected items and a clear "select more" action that re-launches
  the picker or permission flow.
- Android may upgrade a partial grant to full access silently in
  some flows; re-check the actual granted set instead of assuming.
- Better still: if the user only ever picks a few images, use the
  photo picker and request no media permission at all.
- `READ_EXTERNAL_STORAGE` does nothing useful on modern targets.
  Do not request it in new code.

## 4. Notification permission

Since Android 13 (API 33), showing notifications needs the runtime
permission `POST_NOTIFICATIONS`.

- Ask after the user has seen value, for example after they enable a
  reminder or start a download they want told about — not at launch.
- The app must still work fully when notifications are denied.
  Foreground services need special care: the service still runs,
  but its notification may not be visible the usual way, so provide
  an in-app status surface as well.
- Create notification channels with honest importance levels. Do not
  label marketing messages as high importance.

## 5. Protecting data at rest

Use the Android Keystore for keys, and encrypt sensitive files and
preferences. Never write your own encryption.

```kotlin
// EncryptedFile with a Keystore-backed master key
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()

val encryptedFile = EncryptedFile.Builder(
    context,
    File(context.filesDir, "private-notes.dat"),
    masterKey,
    EncryptedFile.FileEncryptionScheme.AES256_GCM_HKDF_4KB,
).build()

encryptedFile.openFileOutput().use { out ->
    out.write(secretBytes)
}
```

- Store tokens in encrypted storage, not plain `SharedPreferences`,
  plain files, or `BuildConfig`.
- Prefer `EncryptedSharedPreferences` replacements from Jetpack
  Security where maintained, or DataStore plus Keystore-backed
  encryption for new code — check the current Jetpack Security
  guidance before choosing, as its recommendations have changed.
- Keys in the Keystore can be set to require device unlock or
  biometric authentication for high-value operations.
- Wipe sensitive data on sign-out, not just the visible session.

## 6. Protecting data in transit

- HTTPS everywhere. Cleartext HTTP is blocked by default on modern
  targets; do not re-enable it globally.
- Use a **network security config** to state the policy in one file:

```xml
<!-- res/xml/network_security_config.xml -->
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.example.com</domain>
    </domain-config>
    <!-- Debug-only exception, in the debug source set only: -->
    <debug-overrides>
        <trust-anchors>
            <certificates src="user" />
        </trust-anchors>
    </debug-overrides>
</network-security-config>
```

- Certificate pinning helps high-risk apps but can lock users out
  when certificates rotate. Pin only with a backup pin and a
  rotation plan, or not at all.
- Validate server responses as untrusted input, even over HTTPS.

## 7. Obfuscation is not security

R8 shrinks and obfuscates release builds. That makes code harder to
read; it does not make secrets safe, logic unbreakable, or an app
tamper-proof. Anything inside the app bundle — keys, URLs, rules —
can be extracted by a determined reader.

- Keep real secrets and real authorization checks on a server.
- Use Play Integrity API where the risk justifies it, and treat its
  verdict as one signal, not proof.
- Still enable R8 for release: smaller size, and it raises the bar
  for casual copying. Just do not count it as a security control.

## 8. Privacy Sandbox, Data safety, and account deletion

Shipping includes declarations, not just code:

- **Data safety section (Play Console):** declare what data the app
  collects, shares, and why, matching what the code actually does —
  including data handled by third-party SDKs. Update it whenever a
  new SDK or feature changes the answer.
- **Privacy policy:** required when the app accesses sensitive data;
  link it in the Console and inside the app.
- **Account and data deletion:** Play requires apps with account
  creation to offer account deletion inside the app and through a
  web link, and to let users request data deletion. Build the flow
  before you need it; deleting an account must delete or anonymize
  the associated personal data on the server too.
- **Privacy Sandbox on Android:** advertising features are moving to
  privacy-preserving APIs (Topics, Protected Audience, Attribution
  Reporting) as third-party identifiers are restricted. If the app
  shows ads, follow the current Privacy Sandbox guidance instead of
  building on device identifiers.
- **Identifiers:** do not use the advertising ID or hardware IDs for
  analytics or tracking beyond their allowed purposes. Prefer
  app-scoped, resettable IDs you generate yourself.

## 9. Everyday security habits

- Keep dependencies updated; most real incidents are known bugs in
  old libraries, not clever attacks.
- Set `android:exported` explicitly on every component, and export
  nothing without a reason.
- Validate deep links and intent extras as untrusted input.
- Do not log tokens, personal data, or file contents — in release
  or debug logs that can leave the device.
- Back up rules: exclude tokens and sensitive files from Android
  backup and device transfer unless the user expects them moved.

## 10. Checklist

- [ ] Every permission is requested at point of use, with rationale.
- [ ] Partial media access is handled as a normal state.
- [ ] Notifications are requested after value, not at launch.
- [ ] Tokens and private files are encrypted with Keystore keys.
- [ ] Network security config forbids cleartext for real domains.
- [ ] No secret, key, or password exists in source or history.
- [ ] Data safety section matches the code and its SDKs.
- [ ] In-app and web account/data deletion flows exist.
- [ ] R8 is on for release, and not treated as a security control.

## Official links

- Request permissions: https://developer.android.com/training/permissions/requesting
- Partial media access: https://developer.android.com/training/data-storage/shared/media
- Notification permission: https://developer.android.com/develop/ui/compose/notifications/notification-permission
- Jetpack Security / Keystore: https://developer.android.com/privacy-and-security/keystore
- Network security config: https://developer.android.com/privacy-and-security/security-config
- Data safety section: https://support.google.com/googleplay/android-developer/answer/10787469
- Account deletion requirements: https://support.google.com/googleplay/android-developer/answer/13327111
- Privacy Sandbox on Android: https://developer.android.com/design-for-safety/privacy-sandbox
