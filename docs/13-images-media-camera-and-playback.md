# Images, Media, Camera, and Playback

This guide covers loading remote images, taking photos, letting the user pick media, and playing audio and video. Each job has one current recommended library. Using the current one matters: older libraries miss scoped-storage, Compose, and lifecycle fixes.

| Job | Use | Avoid for new work |
| --- | --- | --- |
| Images in Compose | Coil 3 | — |
| Images in View-heavy screens | Glide 5 | — |
| Camera | CameraX 1.6.2 | Direct Camera2 code |
| Audio / video playback | Media3 1.11.1 (ExoPlayer inside it) | Standalone `exoplayer2` |
| Picking photos / video | Android photo picker | Storage permission requests |

Picasso is deprecated in practice for new projects: it has no Compose support and its development has stalled. Do not start new work on it.

## 1. Images with Coil 3 (Compose first)

Coil 3 moved to Kotlin Multiplatform and a new group and package. The Compose artifact alone does not fetch from the network — the network artifact is a separate, required dependency.

```kotlin
// build.gradle.kts
dependencies {
    implementation("io.coil-kt.coil3:coil-compose:3.3.0")
    implementation("io.coil-kt.coil3:coil-network-okhttp:3.3.0")
    // Ktor instead of OkHttp in KMP code:
    // implementation("io.coil-kt.coil3:coil-network-ktor3:3.3.0")
}
```

```kotlin
import coil3.compose.AsyncImage

@Composable
fun ArticleImage(url: String, modifier: Modifier = Modifier) {
    AsyncImage(
        model = url,
        contentDescription = null, // decorative; describe real content
        modifier = modifier,
        contentScale = ContentScale.Crop,
    )
}
```

Practical rules:

- Always give the image a fixed size (modifier or layout) so the list does not jump while images load.
- Provide a placeholder and an error painter for slow networks.
- Ask the server for a sized image when it supports one; do not download a 4000-pixel photo into a 200-pixel thumbnail.
- Coil caches in memory and on disk by default. Leave the defaults unless profiling shows a problem.
- In KMP shared code the import is `coil3.*`, not `coil.*`.

## 2. Images with Glide 5 (View-heavy apps)

If most screens are still Views and RecyclerViews, Glide is the pragmatic choice. It is mature, handles RecyclerView recycling well, and integrates with lifecycle automatically.

```kotlin
// build.gradle.kts
dependencies {
    implementation("com.github.bumptech.glide:glide:5.0.5")
}
```

```kotlin
Glide.with(imageView)
    .load(url)
    .placeholder(R.drawable.placeholder)
    .error(R.drawable.image_error)
    .centerCrop()
    .into(imageView)
```

Do not use Glide and Coil for the same screens in one app. Pick per app, not per screen, so there is one cache and one set of defaults. For a Compose-first app, that pick is Coil 3.

## 3. Picking photos: use the photo picker

The Android photo picker lets the user choose specific photos or videos without any storage permission. It is the default choice for "attach a picture" flows.

```kotlin
val pickMedia = rememberLauncherForActivityResult(
    ActivityResultContracts.PickVisualMedia()
) { uri: Uri? ->
    if (uri != null) viewModel.onImagePicked(uri)
}

Button(onClick = {
    pickMedia.launch(
        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
    )
}) { Text("Choose a photo") }
```

- Use `PickMultipleVisualMedia` when the user may select several items.
- The picker is available on older Android versions through Google Play services / AndroidX backports; check availability and fall back to `OpenDocument` if needed.
- A picked URI grants read access to that item only. If you need the access later, copy the file into app storage or take a persistable URI permission for document flows.
- Never request `READ_EXTERNAL_STORAGE` or broad media permissions just to let the user pick one photo. See the permissions guide.

## 4. Camera with CameraX 1.6.2

CameraX is a lifecycle-aware Jetpack library on top of Camera2. It handles device differences that make raw Camera2 code fragile.

```kotlin
// build.gradle.kts
dependencies {
    val camerax = "1.6.2"
    implementation("androidx.camera:camera-core:$camerax")
    implementation("androidx.camera:camera-camera2:$camerax")
    implementation("androidx.camera:camera-lifecycle:$camerax")
    implementation("androidx.camera:camera-view:$camerax")
    implementation("androidx.camera:camera-extensions:$camerax")
}
```

```kotlin
val cameraProvider = ProcessCameraProvider.getInstance(context).await()
val preview = Preview.Builder().build().also {
    it.surfaceProvider = previewView.surfaceProvider
}
val imageCapture = ImageCapture.Builder()
    .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
    .build()

cameraProvider.unbindAll()
cameraProvider.bindToLifecycle(
    lifecycleOwner, CameraSelector.DEFAULT_BACK_CAMERA, preview, imageCapture
)
```

Guidance:

- Request the `CAMERA` runtime permission only when the user opens a camera feature, and explain why in plain words first.
- Save photos into app-specific storage, or into the shared gallery through `MediaStore` when the user expects them in the gallery.
- Test on a real device. Emulator cameras hide focus, rotation, and low-light problems.
- For scanning or face detection, add ML Kit as a CameraX analyzer instead of writing frame handling by hand.
- Release is automatic when bound to a lifecycle owner — bind to the right owner, not the application, for preview use cases.

## 5. Playback with Media3 1.11.1 and ExoPlayer

Media3 is the single Jetpack media library. ExoPlayer now lives inside Media3 as `media3-exoplayer`; the old standalone `com.google.android.exoplayer2` artifacts are deprecated and should not be used for new work.

```kotlin
// build.gradle.kts
dependencies {
    val media3 = "1.11.1"
    implementation("androidx.media3:media3-exoplayer:$media3")
    implementation("androidx.media3:media3-ui:$media3")
    implementation("androidx.media3:media3-session:$media3")
    // Optional: HLS / DASH streaming modules
    implementation("androidx.media3:media3-exoplayer-hls:$media3")
    implementation("androidx.media3:media3-exoplayer-dash:$media3")
}
```

```kotlin
val player = ExoPlayer.Builder(context).build()
player.setMediaItem(MediaItem.fromUri(videoUri))
player.prepare()
player.playWhenReady = true
```

Rules for reliable playback:

- Build the player in a lifecycle-aware place and call `player.release()` when done. Players hold native resources.
- For background audio, put the player in a `MediaSessionService` so system media controls, Bluetooth, and Android Auto work. That service is a foreground service — see the background work guide for its permission and notification duties.
- In Compose, host `PlayerView` through `AndroidView`, or use the Media3 Compose UI artifacts where they fit.
- Handle errors: network loss, unsupported format, and DRM failure each need a different user message and retry choice.
- Respect audio focus: pause or duck when another app takes focus, and resume only when it is polite to do so.
- Prefer adaptive streaming (HLS or DASH) for long video so quality adjusts to the connection instead of stalling.

## 6. Performance and privacy notes

- Downsample large camera photos before upload; send a sized copy, keep the original only if the user needs it.
- Strip location metadata (EXIF GPS) from photos before sharing them publicly, unless the user explicitly wants it kept.
- Cache media on Wi-Fi-friendly terms: do not auto-download large video on mobile data without a setting.
- Give every playable item a content description and captions where the source provides them. Accessibility is part of playback.

## 7. Checklist

- [ ] Coil 3 has both `coil-compose` and a network artifact.
- [ ] No new code uses Picasso or standalone `exoplayer2`.
- [ ] Photo selection uses the photo picker, not a permission.
- [ ] Camera is CameraX, bound to a lifecycle owner.
- [ ] Playback is Media3; background audio uses a media session.
- [ ] Players are released; images have fixed sizes and placeholders.
- [ ] EXIF location is stripped before public sharing.

## Official links

- Coil 3: https://coil-kt.github.io/coil/
- Glide: https://bumptech.github.io/glide/
- CameraX: https://developer.android.com/media/camera/camerax
- Media3: https://developer.android.com/media/media3
- ExoPlayer in Media3: https://developer.android.com/media/media3/exoplayer
- Photo picker: https://developer.android.com/training/data-storage/shared/photo-picker
- MediaStore: https://developer.android.com/training/data-storage/shared/media
