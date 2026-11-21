# Part 1: Code Review of EarningsScreen

## 1. Problem List (Ordered by User Impact — Worst First)

---

### Priority 1: Network Storm & Infinite Rebuild Loop (`api.fetchEarnings()` in `build()`)
* **What the user experiences:** 
  Screen freezes, rapid UI flickering, phone overheats, aggressive battery drain, and app crashes on low-RAM devices (~₹8,000 phones). High cellular data consumption.
* **Why it happens (Framework mechanics):** 
  In Flutter, the `build(BuildContext context)` method must be a pure, idempotent function without side effects. Here, `api.fetchEarnings().then(...)` is called synchronously on every frame build. When the network response resolves, `setState()` is invoked. Calling `setState()` marks the element as dirty and schedules another build. This new build triggers another `api.fetchEarnings()` call, which resolves and calls `setState()` again—causing an infinite network request-rebuild storm.
* **The Fix:** 
  Move `api.fetchEarnings()` completely out of `build()`. Manage state with a dedicated `EarningsCubit` / BLoC where requests are initiated during Cubit creation or screen initialization, keeping the widget declarative.

---

### Priority 2: Stream Subscription Leak & Duplicate Transactions (`api.walletUpdates().listen()` in `build()`)
* **What the user experiences:** 
  Duplicate transactions flood the screen. For a single real-world payout, the teen sees 5, 10, or 20 identical earnings rows. As the screen stays open longer, the app slows down to a crawl and eventually suffers an Out Of Memory (OOM) crash.
* **Why it happens (Framework mechanics):** 
  Every time `build()` is executed, a brand new `StreamSubscription` is created and attached to `api.walletUpdates()`. None of the previous subscriptions are canceled, nor is their reference even stored. If `build()` executes 15 times, there are 15 active listeners. When one wallet update event arrives, all 15 listeners trigger `setState()` and insert duplicate entries into `earnings`. Furthermore, these abandoned listeners hold references to the `State` object, creating a massive memory leak.
* **The Fix:** 
  Subscribe once inside `initState()`, store the `StreamSubscription<WalletUpdate>`, and explicitly call `subscription.cancel()` inside `dispose()`. Additionally, deduplicate incoming updates using unique transaction IDs.

---

### Priority 3: Non-Virtualized List Crashing Low-End Devices (`SingleChildScrollView` + `Column` with 3,000 Items)
* **What the user experiences:** 
  Opening the screen takes several seconds or instantly crashes the app (OOM). Scrolling is choppy, dropped frames (jank), and touches become unresponsive.
* **Why it happens (Framework mechanics):** 
  `SingleChildScrollView` with a `Column` forces Flutter to instantiate, layout, paint, and hold RenderObjects for **all 3,000 items in memory simultaneously**, even though only 6-8 items fit on screen. On a ₹8,000 device with 2GB–3GB RAM and low heap limits, creating 3,000 widget subtrees and render boxes exhausts heap memory and monopolizes the UI thread.
* **The Fix:** 
  Replace with `ListView.builder()`. `ListView.builder` uses viewport virtualization (slivers), instantiating and recycling only the items currently visible on screen plus a small cache extent. For budget phones, adding a fixed `itemExtent` allows $O(1)$ scroll offset calculation without layout measurement.

---

### Priority 4: Frame-Dropping Currency Formatting Inside Tile Rendering (`formatCurrency(e.amount)`)
* **What the user experiences:** 
  Severe scroll stuttering and jank. The list does not feel like 60 FPS or even 30 FPS.
* **Why it happens (Framework mechanics):** 
  `formatCurrency()` parses locale data on every call, taking ~3ms. When building items:
  $$3,000 \text{ items} \times 3\text{ ms} = 9,000\text{ ms } (9 \text{ seconds of pure CPU blocking time})$$
  Even with lazy loading, rendering one screen of 8 items takes $8 \times 3\text{ ms} = 24\text{ ms}$. Since a 60 FPS frame budget is **16.6ms**, taking 24ms just for string formatting guarantees dropped frames.
* **The Fix:** 
  Pre-format currency strings in the data layer / view model, or use a cached, lightweight formatter that does not re-parse locale data per item.

---

### Priority 5: Async Gap Without `mounted` Check & Stale Context (`api.fetchDetail()` in `onTap`)
* **What the user experiences:** 
  If the user taps a tile and immediately presses the back button while the detail is loading, the app logs errors or crashes with `setState() called after dispose()`. Furthermore, passing a stale `BuildContext` to `Navigator.push()` can push onto a dead navigator or cause memory leaks.
* **Why it happens (Framework mechanics):** 
  `await api.fetchDetail(e.id)` suspends execution. During those hundreds of milliseconds of network latency, the user can pop the screen. When the future completes, calling `setState()` on an unmounted `State` throws a framework error.
* **The Fix:** 
  Always verify `if (!mounted) return;` immediately after any `await` before calling `setState()` or using `context`.

---

### Priority 6: Race Condition Between Initial Fetch and Live Stream
* **What the user experiences:** 
  A user receives a real-time earnings notification while the screen is opening, sees it appear for a fraction of a second, and then it mysteriously vanishes!
* **Why it happens (Framework mechanics):** 
  If a `walletUpdates` event arrives before `fetchEarnings()` resolves, it prepends the item to `earnings`. When `fetchEarnings()` finally completes, `earnings = data` completely overwrites the list, obliterating the newly arrived live update.
* **The Fix:** 
  Merge fetched data with the current list using a `Set<String>` of unique transaction IDs so live updates are never wiped by a late-arriving initial batch.

---

### Priority 7: Broken Initial State (`loading = false`) & Missing Error/Empty States
* **What the user experiences:** 
  When opening the screen, the user sees an empty blank screen for 1-2 seconds instead of a loader. If their network fails, the screen remains permanently blank with no error message and no retry option.
* **Why it happens (Framework mechanics):** 
  `bool loading = false;` is initialized as false. In `build()`, `loading ? Spinner : Content` immediately renders the empty `SingleChildScrollView` before the API call even returns. There is no `try/catch` or error variable.
* **The Fix:** 
  Represent screen state as an explicit state machine (`Loading`, `Loaded`, `Error`, `Empty`) and default to `Loading`.

---

## 2. Guardrails for the Other 59 Screens (3-5 Sentences)

1. **Architectural Standard & Separation of Concerns:** Enforce a strict architectural boundary (e.g., BLoC, async_redux, or Notifier with Repository pattern) where widgets are purely declarative views and zero asynchronous side-effects or network calls are permitted inside `build()`.
2. **Automated Static Analysis & Custom Lints:** Configure strict `analysis_options.yaml` rules (including `use_build_context_synchronously`, `cancel_subscriptions`, and custom `custom_lint` rules) to fail CI builds if un-cancelled subscriptions or unmounted context usages are detected.
3. **Reusable Base UI Components:** Provide battle-tested company-wide widgets like `AppPagedListView` and `AsyncStateScaffold` that standardize loading, error with retry, empty states, and viewport virtualization across all 60+ screens.
4. **Low-End Performance CI Benchmarking:** Integrate Flutter driver / integration tests on low-spec device profiles (2GB RAM, throttled CPU) into CI pipelines to monitor frame rasterization times and prevent memory regressions before release.
