# Part 3: Production Scenario — Ad SDK Crash on v6.4.0 Rollout

## 1. Chat Message to Founder (Slack / WhatsApp)

> **"Hey Anik, I strongly recommend halting the v6.4.0 rollout immediately at 20%.**
>
> Crash-free users dropped from 99.6% to 98.1% in the rollout group—that is ~15,000 extra crashes per million sessions, occurring right on app resume. 
> 
> Halting stops the bleeding for the remaining 80% of our teenagers while preserving current ad revenue on the stable v6.3.x fleet.
> 
> I am actively investigating the Crashlytics stack traces and device breakdown now. I will update you with root-cause findings and our fix-forward timeline by 2:00 PM."

---

## 2. Investigation Plan for the Day

### Step 1: Crashlytics Immediate Deep-Dive (First 30 Minutes)
* **Stack Trace Analysis:** Identify the exact native method channel that throws `PlatformException` (e.g., `showAd`, `resumeBanner`, or `loadInterstitial`). Check if it’s a null pointer, illegal state exception (`Activity is finishing`), or unattached window token.
* **Timing & Lifecycle:** Check the Crashlytics Breadcrumbs leading up to the crash. Is it occurring during `didChangeAppLifecycleState` (`AppLifecycleState.resumed`), on return from background, or after lock screen unlock?
* **Session vs. User Impact:** Determine if the crash happens to every user repeatedly on resume, or is concentrated on a subset of high-frequency power users.

### Step 2: Device & OS Pattern Identification
* **Android OS Versions:** Filter Crashlytics by Android version. Android 12+ introduced aggressive background activity start restrictions; Android 14 introduced strict broadcast receiver restrictions.
* **OEM Customizations:** Check if crashes disproportionately affect aggressive RAM-killing OEMs (Xiaomi/MIUI, Transsion/Infinix/Tecno, Samsung) where the Android Activity was destroyed by the OS while backgrounded, leaving the Flutter engine with a detached native activity reference when resumed.
* **Memory & Storage:** Check free RAM/disk metrics at the time of crash.

### Step 3: Git Diff & Code Audit (Since Ad SDK Wasn't Updated)
Even though the Ad SDK dependency version did not change:
1. **Activity Lifecycle Changes:** Did we change `MainActivity.kt`, Android `launchMode`, or how `WidgetsBindingObserver` handles `AppLifecycleState.resumed` in Flutter?
2. **Transitive Dependency Conflicts:** Check `pubspec.lock` and `gradle.lockfile` diffs. Did another package bump Google Play Services Ads Identifier or AndroidX Core libraries transitively?
3. **Screen Hierarchy:** Did we show ads on resume on a screen that was already popped or being disposed?

---

## 3. Decision Framework: Halt vs. Hold at 20% vs. Fix-Forward

| Decision | When to choose | Action |
| :--- | :--- | :--- |
| **Halt (Recommended)** | When crash rate exceeds 1% drop on critical app paths (resume) and degrades brand trust for new users. | Stop rollout in Google Play Console immediately. 80% of users remain unaffected on stable v6.3.x. |
| **Hold at 20%** | Only if the crash is strictly isolated to a tiny, non-core cohort (e.g., Android 8 devices representing <1% of revenue) and more telemetry data is required to reproduce. | Keep at 20% for max 2 hours while capturing logs, then halt if no quick workaround exists. |
| **Fix-Forward** | Once the exact bug is identified, verified with automated/manual tests, and can be patched within hours. | Ship hotfix `v6.4.1` directly to 10% -> 50% -> 100% rollout. |

---

## 4. Remote Config / Feature Flag Lever

### What lever I wish we had:
```json
{
  "ads_on_resume_enabled": false,
  "ad_provider_fallback": "none",
  "min_resume_interval_seconds": 60
}
```

### Would I have shipped one?
**Yes, 100%.** 

Third-party ad SDKs are notorious for asynchronous lifecycle quirks, aggressive memory caching, and native thread crashes across OEM skins. Shipping third-party ad initialization or resume triggers without a Remote Config kill-switch is a massive liability. 

With `ads_on_resume_enabled: false`, we could have flipped this toggle in Firebase Remote Config within **60 seconds**, instantly stopping all crashes worldwide without halting the app release, without Play Store review delays, and without sacrificing the rest of the feature updates in v6.4.0.
