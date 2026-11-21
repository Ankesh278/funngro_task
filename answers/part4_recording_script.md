# Part 4: 5-Minute Walkthrough Recording Script & Talking Points

> **Format:** Loom, screen capture, or phone recording your screen.  
> **Target Duration:** 3 to 4.5 minutes (Max 5 minutes).  
> **Tone:** Relaxed, conversational, talking to an engineering colleague. No script-reading!

---

## ⏱️ Video Breakdown

```
[0:00 - 1:45] Part 2 Live Demo: Projects Infinite Scroll & Error/Retry
[1:45 - 3:00] Part 1 Analysis: The Worst Bug & Why It Ranked #1
[3:00 - 4:00] Part 3 Production Scenario: Halting Rollout & Remote Config
[4:00 - 4:45] Ambiguity & Question I'd Ask the Funngro Team
```

---

## 🗣️ What to Say & Demo (Step-by-Step)

### 1. Part 2 Live Demo: Projects Pagination (0:00 - 1:45)
* **Action:** Launch the app on your Android emulator or phone. Show the **"Part 2: Projects"** tab.
* **Talking Points:**
  * *"Hey everyone! Here is the running Flutter app for the Funngro assessment. On the bottom navigation, you can switch between Part 2 and Part 1."*
  * *"Let's look at Part 2: Projects screen. It's connected directly to the provided `ProjectsApi` which has a 900ms delay and a 1-in-5 failure rate."*
  * *"For state management, I used **Cubit (flutter_bloc)**. The `ProjectsCubit` emits an immutable `ProjectsState` that preserves all loaded projects on page errors, manages request epochs to ignore stale refresh responses, and separates the initial load error from pagination footer errors."*
  * *(Scroll down smoothly)*: *"As I scroll near the bottom, it triggers the next page. Here you see the footer loading indicator: 'Loading more projects...'."*
  * *(Wait for an API error to trigger)*: 
    * *"Notice right here: Page 2 failed with a server error! Crucially, as per the requirements, **the already-loaded 40 items are not lost**. The user doesn't get kicked out to an empty screen."*
    * *(Click the red 'Retry Page 2' button on camera)*: *"Now I hit 'Retry Page 2'—it re-fetches specifically Page 2, recovers cleanly, and appends the new items!"*
  * *(Scroll to page 7)*: *"Once we cross Page 7, the API returns an empty list, and the footer transitions into a clear 'End of list' state with all 160 projects loaded."*
  * *(Pull down from the top)*: *"And if I pull-to-refresh from the top, it resets back to Page 0 seamlessly."*

---

### 2. Part 1: The Worst Bug & Why It Ranked #1 (1:45 - 3:00)
* **Action:** Switch to the code or briefly open the "Part 1: Earnings" tab.
* **Talking Points:**
  * *"Moving to Part 1: I analyzed the provided `EarningsScreen`. There are several critical flaws, but I ranked **calling `api.fetchEarnings()` inside `build()` as the absolute worst bug**."*
  * *"Why? In Flutter, `build()` must be a pure, idempotent function. When you fire an asynchronous network call inside `build()`, upon completion it calls `setState()`. Calling `setState()` marks the widget dirty and rebuilds the screen, which calls `build()` again, which triggers another API request. This causes an infinite network loop and battery drain that will bring down both the backend and an ₹8,000 phone."*
  * *"The second worst was attaching `api.walletUpdates().listen()` inside `build()` without cancellation. Every rebuild created a duplicate listener, multiplying earnings cards and causing huge memory leaks."*
  * *"In my rewrite, I moved all subscriptions and API calls into `initState()`, canceled the subscription in `dispose()`, replaced `SingleChildScrollView + Column` with `ListView.builder` for 60 FPS virtualization across 3,000 items, and handled deduplication cleanly."*

---

### 3. Part 3: Production Rollout Scenario (3:00 - 4:00)
* **Talking Points:**
  * *"For Part 3, we had a scenario where v6.4.0 dropped crash-free users from 99.6% to 98.1% on app resume due to the Ad SDK."*
  * *"My recommendation to Anik was: **Halt the rollout immediately** at 20%. A 1.5% drop in production is unacceptable for teenagers using our app daily. Halting stops the crash from spreading to the remaining 80% while we investigate."*
  * *"My investigation plan focuses on Android 12+ activity recreation and background restrictions, and check whether our native Activity lifecycle changed on resume."*
  * *"And crucially: I would have shipped a Remote Config toggle `enable_ad_on_resume: false`. If we had that, we could have resolved this crash globally within 60 seconds without needing a Play Store hotfix."*

---

### 4. Ambiguity & Question for the Team (4:00 - 4:45)
* **Talking Points:**
  * *"One decision I had to make was about the 3,000 earnings items. Even though `ListView.builder` solved the UI rendering jank, deserializing a 3,000-item JSON response on a ₹8,000 Android device takes significant CPU time on the Dart thread."*
  * *"The question I would ask the Funngro backend team is: **Can we introduce cursor-based pagination on the backend for earnings history, just like we have on the projects API?** That way we never pull more than 20-50 transactions over the wire at a time."*
  * *"Thanks for watching! Looking forward to discussing this in the next round."*
