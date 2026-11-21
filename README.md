# Funngro Mobile Engineering Assessment (Flutter)

This repository contains the complete solution for the **Funngro Mobile Engineer Take-Home Assessment**.

---

## 📁 Repository Structure

```
.
├── lib/
│   ├── main.dart                                # Dual-tab navigation hub with MultiBlocProvider
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart                  # Centralized color palette
│   │   │   └── app_text_styles.dart             # Centralized typography hierarchy
│   │   ├── theme/
│   │   │   └── app_theme.dart                   # Centralized ThemeData (Material 3)
│   │   └── utils/
│   │       └── currency_formatter.dart          # Zero-allocation fast INR formatter
│   ├── part1_earnings/
│   │   ├── models/earning.dart                  # Domain models (Earning, Detail, WalletUpdate)
│   │   ├── fake_earnings_api.dart               # Simulates 3,000 items & live wallet stream
│   │   ├── detail_screen.dart                   # Transaction details screen
│   │   ├── cubit/
│   │   │   ├── earnings_cubit.dart              # Stream lifecycle, deduplication & state emission
│   │   │   └── earnings_state.dart              # Immutable EarningsState
│   │   └── earnings_screen_rewritten.dart       # Declarative UI with BlocConsumer & ListView.builder
│   └── part2_projects/
│       ├── models/project.dart                  # Project and ApiException models
│       ├── projects_api.dart                    # Official assessment ProjectsApi (20% failure, 900ms)
│       ├── cubit/
│       │   ├── projects_cubit.dart              # Infinite scroll pagination, retry & pull-to-refresh
│       │   └── projects_state.dart              # Immutable ProjectsState with copyWith
│       └── projects_screen.dart                 # Declarative UI with BlocConsumer & footer states
├── test/
│   └── widget_test.dart                         # Smoke tests & API resilience tests
└── README.md
```

---

## 🚀 How to Run the App

1. Ensure Flutter is installed (`flutter --version` >= 3.12).
2. Clone this repository:
   ```bash
   git clone https://github.com/Ankesh278/funngro_task.git
   cd funngro_task
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run tests:
   ```bash
   flutter test
   ```
5. Launch on an Android device or emulator:
   ```bash
   flutter run
   ```

---

## 📱 Features & Highlights

### Part 1: Rewritten Earnings Screen
* **Lifecycle-Safe Stream:** `StreamSubscription` initialized in `EarningsCubit` and canceled in `close()`.
* **Zero UI Jank with 3,000 Items:** Replaced `SingleChildScrollView + Column` with `ListView.builder` + fixed `itemExtent: 74.0` for guaranteed 60 FPS viewport virtualization on ₹8,000 Android phones.
* **Stream & Initial Fetch Merge:** Live wallet updates arriving while initial network fetch is pending are preserved via $O(1)$ `Set<String>` ID deduplication.
* **Instant Currency Formatting:** Bypasses heavy locale re-parsing with an optimized regex Indian numbering formatter (~0.002ms vs ~3ms per item).
* **Async & Lifecycle Guards:** All async calls verify `mounted` before executing `Navigator.push()`.

### Part 2: Projects Infinite Scroll with Flaky API
* **Visually Distinct States:**
  1. *First-load spinner*
  2. *Page-load footer spinner*
  3. *Error with Retry (preserving all existing items)*
  4. *End of list indicator (Pages 0..7, 160 projects)*
  5. *Pull-to-refresh (resets to page 0)*
* **Resilient State Management:** If Page 2 fails due to the 20% random failure rate, all items from Page 0 and 1 remain rendered. Clicking **"Retry Page 2"** re-requests specifically Page 2.
* **Concurrency Guards:** Scroll debounce prevents firing duplicate network calls while a page is loading.

---

## 📝 Part 1: Code Review of EarningsScreen

### Problem List (Ordered by User Impact — Worst First)

1. **#1 Worst Bug: API Call Inside `build()` (`api.fetchEarnings()`)**
   * *User Experience:* Screen freeze, rapid UI flickering, phone overheating, aggressive battery drain, and app crashes on budget phones (~₹8,000). High cellular data usage.
   * *Framework Mechanics:* `build()` must be idempotent. Calling async network calls inside `build()` triggers `setState()` on completion, which schedules another build, leading to an **infinite network request-rebuild storm**.
   * *Fix:* Move fetching out of `build()` into `EarningsCubit` / `initState()`.

2. **#2 Bug: Stream Subscription Leak Inside `build()` (`api.walletUpdates().listen()`)**
   * *User Experience:* Duplicate transactions flood the screen; a single payout appears 10+ times. Memory leaks lead to an Out Of Memory (OOM) crash.
   * *Framework Mechanics:* Every rebuild attaches a brand new `StreamSubscription` without canceling prior ones. 10 rebuilds = 10 parallel listeners.
   * *Fix:* Manage subscription lifecycle inside `EarningsCubit` and cancel via `close()` / `dispose()`.

3. **#3 Bug: Non-Virtualized List with 3,000 Items (`SingleChildScrollView` + `Column`)**
   * *User Experience:* Screen opening freeze (5-10s) or crash. Scrolling is janky with severe dropped frames.
   * *Framework Mechanics:* `Column` forces Flutter to instantiate and layout all 3,000 items in memory at once. Budget devices (~2GB RAM) cannot support this heap allocation.
   * *Fix:* Use `ListView.builder` with fixed `itemExtent: 74.0` for sliver viewport virtualization (60 FPS).

4. **#4 Performance Bug: Repeated Currency Formatting (`formatCurrency(e.amount)`)**
   * *User Experience:* Severe scroll stuttering and jank.
   * *Framework Mechanics:* Locale parsing takes ~3ms per call ($3,000 \times 3\text{ms} = 9\text{ seconds}$ of CPU blocking). Exceeds the 16.6ms 60 FPS frame budget.
   * *Fix:* Use a lightweight regex-based Indian currency formatter (`AppCurrencyFormatter`, ~0.002ms).

5. **#5 Bug: Async Gap Without `mounted` Check (`api.fetchDetail()`)**
   * *User Experience:* Navigation errors and `"setState() called after dispose()"` when tapping a tile and popping the screen.
   * *Framework Mechanics:* Using `context` or state across an asynchronous suspension without verifying `mounted`.
   * *Fix:* Add `if (!context.mounted) return;` after `await`.

6. **#6 Bug: Race Condition Between Initial Fetch and Live Stream**
   * *User Experience:* Real-time earnings notification arrives while opening the screen and vanishes when initial fetch resolves.
   * *Framework Mechanics:* `earnings = data` completely overwrote list state, wiping in-flight wallet events.
   * *Fix:* Merge initial batch with live items using a `Set<String>` of unique transaction IDs.

7. **#7 Bug: Broken Initial State (`loading = false`) & Missing Error UI**
   * *User Experience:* Initial blank screen flicker; network errors leave the teen stuck with an empty screen and no retry option.
   * *Framework Mechanics:* No error handling or explicit state machine.
   * *Fix:* Represent state explicitly (`loading`, `success`, `error`, `empty`) with retry mechanisms.

### Guardrails for the Other 59 Screens (3-5 Sentences)
1. **Architectural Standard:** Enforce strict separation of concerns using BLoC/Cubit with Repository patterns; forbid network/stream side effects in UI widgets.
2. **Automated Static Analysis:** Enable `use_build_context_synchronously`, `cancel_subscriptions`, and custom lints in CI pipelines.
3. **Reusable Design System:** Provide standard shared components (`AppPagedListView`, `AsyncStateScaffold`) with built-in virtualization, loading, and error states.
4. **Performance CI Benchmarking:** Profile frame rasterization times and memory allocations on low-spec device emulators before shipping releases.

---

## 🚨 Part 3: Production Rollout Scenario

### 1. Chat Message to Founder
> *"Hey Anik, I strongly recommend halting the v6.4.0 rollout immediately at 20%. Crash-free users dropped from 99.6% to 98.1% in the rollout group (~15k extra crashes per million sessions) occurring on app resume. Halting stops the crash from spreading to the remaining 80% while preserving ad revenue on the stable v6.3.x fleet. I am investigating the Crashlytics stack traces and device breakdown now and will share a root-cause update and fix timeline by 2:00 PM."*

### 2. Daily Investigation Plan
* **Crashlytics Triage:** Analyze the exact native method channel throwing `PlatformException` (e.g. `showAd`, `resumeBanner`), null pointer, or detached activity token.
* **Device / OS Patterns:** Check Android 12+ background activity start restrictions and aggressive OEM RAM-killing (Xiaomi, Samsung) on app resume.
* **Decision Framework:** 
  * **Halt (Recommended):** Critical path crash degrades brand trust; halt prevents spreading to 80%.
  * **Hold at 20%:** Only if isolated to a tiny non-core cohort requiring more telemetry.
  * **Fix-Forward:** Ship hotfix `v6.4.1` once root cause is reproduced and verified.
* **Remote Config Lever:** 
  We should have shipped `enable_ads_on_resume: false`. With this toggle, we could disable the crashing resume flow within 60 seconds worldwide without halting the rollout or waiting for Play Store review.

---

## 💡 Assumptions & Questions for Funngro

### Assumptions:
1. Earning and Project IDs are globally unique and immutable, allowing $O(1)$ set deduplication.
2. The Projects fake API terminates when `page > 7` by returning `[]`.
3. If pull-to-refresh fails, preserving already loaded data and showing a SnackBar is superior UX to blowing away the list.

### Questions I Would Ask the Team:
1. *"Can we introduce cursor-based pagination on the backend for earnings history instead of a single 3,000-item payload? JSON deserialization of 3,000 models on a budget Android phone still causes Dart thread latency."*
2. *"Does the wallet update WebSocket/SSE reconnect automatically on flaky 2G/3G networks, and is idempotency handled client-side or server-side?"*
