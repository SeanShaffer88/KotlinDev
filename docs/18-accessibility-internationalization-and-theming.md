# Accessibility, Internationalization, and Theming
## TL;DR
Build for everyone from the start: label every control for TalkBack, use large enough touch targets, respect the user's font size, keep all text in string resources, support right-to-left layouts, and theme with Material 3 — including dynamic color and a proper dark theme. Retrofitting any of these is much harder than starting right.
Official guides: Accessibility https://developer.android.com/guide/topics/ui/accessibility · Compose accessibility https://developer.android.com/jetpack/compose/accessibility · Material 3 https://developer.android.com/jetpack/compose/designsystems/material3
## 1. Accessibility principles
- Every action a sighted user can do must be possible with TalkBack, Switch Access, and a keyboard or D-pad where the device has one.
- Information must never be carried by color alone. Pair color with text, an icon, or a shape — an error also shows an icon and a message, not only a red outline.
- Keep contrast strong: at least 4.5:1 for normal text and 3:1 for large text and essential graphics, in both light and dark themes.
- Test with TalkBack on, large fonts on, and animations reduced. Automated checks catch labels and target size; only a manual pass catches reading order and confusing labels.
Accessibility Scanner and Compose lint help, but they do not replace testing with the real services. Scanner: https://developer.android.com/guide/topics/ui/accessibility/testing
## 2. TalkBack semantics in Views
In View-based UI, TalkBack reads the view hierarchy. Most standard widgets are already accessible; your job is labels and grouping.
```xml
<ImageView android:id="@+id/avatar" android:layout_width="48dp"
    android:layout_height="48dp" android:contentDescription="@string/avatar_description" />
<Button android:id="@+id/save" android:layout_width="wrap_content"
    android:layout_height="wrap_content" android:minHeight="48dp" android:text="@string/save" />
```
- Set `android:contentDescription` on image buttons and meaningful images. Set it to `null`, or mark the view not important for accessibility, for purely decorative images so TalkBack skips them.
- Group related views with a labelled container so TalkBack reads a row like "Ada Lovelace, premium member" once, not as fragments.
- Use headings (`android:accessibilityHeading="true"` on titles) so users can navigate by heading.
- For custom views, set `contentDescription` and class name, add custom actions with `AccessibilityDelegate`, and announce changes with `announceForAccessibility` only when truly needed.
## 3. TalkBack semantics in Compose
Compose builds a semantics tree from your composables. Material components (Button, IconButton, Switch, Slider) already carry the right role, state, and actions. You supply the labels.
```kotlin
@Composable fun SaveButton(onSave: () -> Unit) {
    Button(onClick = onSave) { Text(stringResource(R.string.save)) }
}
@Composable fun AvatarButton(onClick: () -> Unit) {
    IconButton(onClick = onClick) {
        Icon(imageVector = Icons.Default.Person,
            contentDescription = stringResource(R.string.open_profile))
    }
}
```
```kotlin
// Merge a row into one TalkBack stop, with a clear action label.
Row(modifier = Modifier
    .clearAndSetSemantics { contentDescription = "Ada Lovelace, premium member" }
    .clickable(onClickLabel = "Open profile") { openProfile() }
) { Text("Ada Lovelace"); Text("Premium member") }
```
Key APIs: `contentDescription` on `Icon` / `Image` (`null` means decorative); `Modifier.semantics { }` for state, role, custom actions, headings (`heading()`), progress (`progressBarRangeInfo`), and live regions; `clearAndSetSemantics` only when merging children into one label, since overuse hides controls from TalkBack. Toggle and selection state comes free with `Switch`, `Checkbox`, and `RadioButton` in a labelled row — make the whole row clickable.
Test with `composeRule.onNodeWithContentDescription(...)` and by walking the app with TalkBack in order, top to bottom. Semantics guide: https://developer.android.com/jetpack/compose/semantics
## 4. Content descriptions: writing good labels
- Describe what the control **does**, not what it looks like: "Delete note", not "Trash can icon".
- Do not repeat the role: TalkBack adds "button" itself, so use "Save", not "Save button".
- Keep labels short. Long help goes in a hint, a help screen, or a longer semantics description where needed.
- Label images that carry information ("Sales chart, up 12 percent this month"); hide decorative images from accessibility services.
- Update dynamic labels when content changes — a play button that becomes pause must change its description too.
## 5. Touch targets and layout
- Make every touch target at least **48 x 48 dp**, even when the visible icon is 24 dp. Material components do this by default; preserve it when you set custom sizes.
- Keep at least 8 dp between separate targets so they are not hit by mistake.
- Do not rely on hover, long-press alone, or precise gestures for an essential action. Offer a visible button alternative.
- Ensure focus order matches visual order for keyboard, D-pad, and TalkBack swipe navigation. In Compose, avoid custom focus order unless reading order would otherwise be wrong.
Guide: https://developer.android.com/guide/topics/ui/accessibility/principles
## 6. Font scaling and non-linear scaling
Users can set system font size well above 100%. Android scales `sp` text, and from Android 14 font scaling is **non-linear**: large text grows by a smaller factor than small text, so huge headlines do not explode while body text still gets bigger.
- Always size text in `sp`; Compose Material typography uses sp by default. Never size text in `dp`.
- Test at 85%, 100%, 130%, and 200% font scale. Text must wrap or the layout must scroll — never clip, overlap, or push buttons off screen.
- Give containers room to grow: prefer flexible heights over fixed heights for text blocks.
- Check dialogs, list rows, and bottom bars first, since they clip first.
```kotlin
Text(text = title, style = MaterialTheme.typography.titleMedium, // sp-based type
    modifier = Modifier.padding(16.dp)) // dp is for spacing, not text
```
## 7. Internationalization: strings and plurals
Internationalization (i18n) means the app can be translated without code changes. Localization is providing the actual translations.
- Put **every** user-visible string in `res/values/strings.xml`. No hard-coded text in Kotlin, layouts, or Compose — use `stringResource(R.string.…)` in Compose and `@string/…` in XML.
- Never build sentences by joining pieces, because word order differs by language. Use one full string with placeholders:
```xml
<string name="items_count">You have %1$d items</string>
<string name="welcome">Welcome back, %1$s</string>
<plurals name="notes_saved">
    <item quantity="one">%d note saved</item>
    <item quantity="other">%d notes saved</item>
</plurals>
```
```kotlin
Text(stringResource(R.string.items_count, count))
val saved = pluralStringResource(R.plurals.notes_saved, count, count)
```
- Use plurals so grammar is correct in every language; languages have different plural rules and some have six forms.
- Format dates, numbers, and currency with locale-aware formatters (`DateTimeFormatter`, `NumberFormat`), never hard-coded patterns like `MM/dd/yyyy` for display.
- Keep string names stable, add a short comment for translators describing where the string appears, and mark strings that must not be translated with `translatable="false"`.
Guides: https://developer.android.com/guide/topics/resources/localization · https://developer.android.com/guide/topics/resources/string-resource
## 8. RTL and layout direction
Languages like Arabic and Hebrew read right to left (RTL). Android mirrors layouts automatically when you use relative attributes.
- In Views use `paddingStart` / `paddingEnd` and `layout_marginStart` / `End`, never `Left` / `Right` for layout. In Compose use `padding(start = …, end = …)` and arrangements that respect `LayoutDirection`.
- Do not mirror icons that point in a physical or playback direction (play, volume, charts). Do mirror directional navigation icons like back/forward arrows — use `autoMirrored` icons in Compose.
- Test with the Arabic locale and with "Force RTL layout" in Developer Options, even before any translation exists, and declare `android:supportsRtl="true"` in the manifest.
Guide: https://developer.android.com/training/basics/supporting-devices/languages#SupportDifferentLayoutDirection
## 9. Per-app languages
Android 13+ lets users pick a language per app, different from the system language. Support it so users are not forced to change their whole device for one app.
- Store locale resources in `res/values-<language>` folders as usual.
- Use the AppCompat per-app language APIs / `LocaleManager` on Android 13+, and declare the locales config so the system Settings page lists your languages.
- Generate the locales config automatically with AGP where possible (`generateLocaleConfig = true`) or provide `res/xml/locales_config.xml`.
- Changing the in-app language should recreate the UI with the new resources and keep the user's place and data.
```xml
<locale-config xmlns:android="http://schemas.android.com/apk/res/android">
    <locale android:name="en-US" /><locale android:name="es" /><locale android:name="ar" />
</locale-config>
```
Guide: https://developer.android.com/guide/topics/resources/app-languages
## 10. Material 3 theming and dynamic color
Theme with Material 3 (`MaterialTheme`) from a single source of truth: color, typography, and shapes. Do not scatter raw hex colors through screens.
```kotlin
private val LightColors = lightColorScheme(primary = Color(0xFF6750A4), onPrimary = Color.White)
private val DarkColors = darkColorScheme(primary = Color(0xFFD0BCFF), onPrimary = Color(0xFF381E72))
@Composable fun AppTheme(dark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val context = LocalContext.current
    val colors = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        dark -> DarkColors
        else -> LightColors
    }
    MaterialTheme(colorScheme = colors, typography = Typography, content = content)
}
```
**Dynamic color** (Android 12+, API 31+) builds a color scheme from the user's wallpaper. Offer it as the default where it fits the brand, with your own light/dark schemes as fallback for older devices and for brands that must keep exact colors. Check that dynamic schemes still meet contrast rules for key screens.
Use semantic theme colors in UI — `primary`, `surface`, `surfaceVariant`, `error`, `onSurface` — not literal colors, so a theme change updates the whole app at once.
Links: https://developer.android.com/jetpack/compose/designsystems/material3 · https://developer.android.com/develop/ui/compose/system/dynamic-color · https://m3.material.io/styles/color/system/overview
## 11. Dark theme
- Provide a real dark theme, not an inverted filter. Dark surfaces are dark greys from the color scheme, text is a lighter tone, and elevation is shown with a lighter surface tint in Material 3.
- Follow the system setting by default (`isSystemInDarkTheme()` in Compose, `AppCompatDelegate` / DayNight in Views), with an in-app Light / Dark / System choice saved as a preference.
- Check images, icons, charts, and screenshot tests in both themes. Avoid pure black for large areas unless the brand requires it, and avoid pure white text on pure black, which is harsh.
- Test dark theme together with large fonts and TalkBack — that combination is what many low-vision users actually run.
Guide: https://developer.android.com/develop/ui/views/theming/darktheme
## Checklist
- [ ] Walked every main screen with TalkBack; order and labels make sense.
- [ ] All interactive images and icons have content descriptions.
- [ ] All touch targets are at least 48 x 48 dp.
- [ ] Layout tested at 200% font scale with no clipped text.
- [ ] No hard-coded user-visible strings; plurals and formats are locale-aware.
- [ ] RTL tested with a forced RTL layout and an RTL locale.
- [ ] Per-app languages listed in system Settings (Android 13+).
- [ ] Light, dark, and dynamic color checked for contrast on key screens.
