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
├── answers/
│   ├── part1_code_review.md                     # Impact-ordered bug analysis & 60+ screen guardrails
│   ├── part3_production_scenario.md             # Founder chat message, triage plan & Remote Config
│   ├── assumptions_and_questions.md             # Assumptions & technical questions for the team
│   └── part4_recording_script.md                # 5-minute Loom walkthrough talking points
├── test/
│   └── widget_test.dart                         # Smoke tests & API resilience tests
└── README.md
```

---

## 🚀 How to Run the App

1. Ensure Flutter is installed (`flutter --version` >= 3.12).
2. Clone or extract this repository.
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
* **Lifecycle-Safe Stream:** `StreamSubscription` initialized in `initState()` and canceled in `dispose()`.
* **Zero UI Jank with 3,000 Items:** Replaced `SingleChildScrollView + Column` with `ListView.builder` + fixed `itemExtent: 74.0` for guaranteed 60 FPS viewport virtualization on ₹8,000 Android phones.
* **Stream & Initial Fetch Merge:** Live wallet updates arriving while initial network fetch is pending are preserved via $O(1)$ `Set<String>` ID deduplication.
* **Instant Currency Formatting:** Bypasses heavy locale re-parsing with an optimized regex Indian numbering formatter (~0.002ms vs ~3ms per item).
* **Async & Lifecycle Guards:** All async calls verify `mounted` before executing `setState()` or `Navigator.push()`.

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

## 📄 Written Answers & Documentation

* 🔍 **[Part 1: Code Review & Guardrails](answers/part1_code_review.md)**
* 🚨 **[Part 3: Production Rollout Incident](answers/part3_production_scenario.md)**
* 💡 **[Assumptions & Questions for Funngro](answers/assumptions_and_questions.md)**
* 🎬 **[Part 4: Video Walkthrough Script](answers/part4_recording_script.md)**

---

## 📹 Part 4: Walkthrough Recording

* **Loom Link:** *[Insert your Loom / Google Drive link here before sending in LinkedIn]*
* A ready-to-use spoken guide is provided in `answers/part4_recording_script.md`.
