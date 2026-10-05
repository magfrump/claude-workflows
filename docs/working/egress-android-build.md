# Egress needed for the Android build in the agent container

Date: 2026-10-05 · Probed from the agent sandbox with `curl -m 10`.

## Summary

Add **`dl.google.com`** (HTTPS, port 443) to the container's egress allowlist. It is the only
host the build needs that is currently blocked. `maven.google.com` is already reachable, but it
only answers with a `301` redirect to `dl.google.com`, so allowing it alone doesn't help.

## Why

- Gradle's `google()` repository is `https://dl.google.com/dl/android/maven2/`. It hosts the
  Android Gradle Plugin (`com.android.application` 8.7.3), every `androidx.*` artifact
  (Compose BOM 2024.10.01, lifecycle, activity, core-ktx) and other `com.google.*`
  artifacts. Nothing else mirrors them.
- AGP 8.7.3 also installs **build-tools 34.0.0** on its own from
  `https://dl.google.com/android/repository/`. The read-only `/opt/android-sdk` image only has
  35.0.0.
- The local Gradle dependency cache (`~/.gradle/caches/modules-2/files-2.1`) is empty, so
  `--offline` can't stand in for network access.

## Host table

| Host | Used for | Status now | Needed |
|---|---|---|---|
| `dl.google.com` | Google Maven (AGP, androidx) + SDK repository (build-tools 34) | **Blocked** (TLS reset, `SSL_ERROR_SYSCALL`) | **Yes** |
| `maven.google.com` | Alias; 301-redirects to `dl.google.com` | 200 | Keep (harmless) |
| `repo.maven.apache.org` | Maven Central (`mavenCentral()`): Kotlin 2.0.21 + Compose compiler plugins, kotlinx, junit | 200 | Yes (already allowed) |
| `repo1.maven.org` | Maven Central alternate host | 200 | Keep |
| `services.gradle.org` | Gradle 8.9 wrapper distribution (already cached in `~/.gradle/wrapper/dists`) | 200 | Keep for fresh volumes |
| `plugins.gradle.org` | Gradle Plugin Portal metadata (`gradlePluginPortal()`, last in `pluginManagement`) | 200 | Keep |
| `plugins-artifacts.gradle.org` | Where the Plugin Portal redirects jar downloads | Blocked | Optional: today's plugins all resolve from Google Maven or Central first; add it if a future plugin is only on the portal |
| `downloads.gradle.org` | Gradle distribution CDN (redirect target for some wrapper versions) | Blocked | Optional |

## Minimal change

```
dl.google.com:443
```

## Verify after updating the container

```bash
curl -sS -m 10 -o /dev/null -w '%{http_code}\n' \
  https://dl.google.com/dl/android/maven2/com/android/application/com.android.application.gradle.plugin/8.7.3/com.android.application.gradle.plugin-8.7.3.pom
# expect 200

ANDROID_HOME=~/.cache/herald-sdk-overlay ANDROID_SDK_ROOT=~/.cache/herald-sdk-overlay \
  ./gradlew :app:assembleDebug :app:testDebugUnitTest
```

The first build also downloads build-tools 34.0.0 into the writable overlay at
`~/.cache/herald-sdk-overlay`. It can't go into the read-only `/opt/android-sdk`.
