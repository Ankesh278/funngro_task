# Assumptions & Questions for the Engineering Team

> *Note from the assessment instructions: "If anything is ambiguous, state your assumption and proceed - and note the question you would have asked us. (We actually score this.)"*

---

## Part 1: Earnings Screen

### Assumptions Made:
1. **Unique Identifiers:** Assumed that all `Earning` and `WalletUpdate` objects possess a globally unique and immutable `id`. Based on this, implemented $O(1)$ deduplication using a `Set<String> _earningIds`.
2. **Natural Ordering:** Assumed that `api.fetchEarnings()` returns historical earnings in descending order (newest first), and that real-time `walletUpdates` represent newly minted transactions that belong at the top (`index: 0`).
3. **In-Flight Stream Race Conditions:** Assumed that real-time wallet stream updates can arrive *while* the initial asynchronous `fetchEarnings()` network request is still pending. Implemented merge logic so late-arriving initial API responses do not overwrite live updates.
4. **Currency Locale Consistency:** Assumed the app operates primarily in India (₹ INR) for Funngro teens, allowing us to replace the heavy 3ms `formatCurrency()` with a high-performance regex-based Indian numbering formatter (`AppCurrencyFormatter.formatInr`).

### Questions I Would Ask the Team:
1. **Cursor Pagination vs. Single 3,000-Item Payload:** 
   *"Does the backend API support cursor-based pagination (e.g., `limit=20&cursor=...`) for earnings history? Even though `ListView.builder` optimizes UI rendering for 3,000 items, deserializing a 3,000-item JSON array on a ₹8,000 budget phone still blocks the Dart thread for 200–400ms during JSON decoding. Can we paginate the network endpoint?"*
2. **Stream Reconnection & Idempotency:** 
   *"When the mobile device toggles between Wi-Fi and mobile data, does the wallet stream socket reconnect automatically and replay unacknowledged events? Does the client need to send a `last_seen_transaction_id` ack, or does the backend handle deduplication?"*
3. **Transaction Details Caching:** 
   *"Are transaction details immutable once settled? If yes, should we cache `EarningDetail` locally in SQLite/Hive or in-memory so tapping the same earning multiple times does not trigger redundant network calls?"*

---

## Part 2: Projects List with Pagination

### Assumptions Made:
1. **End-of-List Termination:** The fake API returns `[]` when `page > 7`. Assumed that an empty list signifies terminal pagination, permanently disabling further scroll triggers and rendering the "End of list" state.
2. **Preserving Loaded Data on Refresh Failure:** If a user initiates a pull-to-refresh while viewing loaded projects and the network fails (1 in 5 chance), assumed that displaying a non-intrusive error SnackBar while keeping existing items intact is strictly better UX than clearing the list and showing a blank error screen.
3. **Page Fetch Guards:** Assumed that if page 2 fails, the retry action must request page 2 again (not page 0 or page 3), and fast scrolling should never fire parallel requests for the same page.

### Questions I Would Ask the Team:
1. **Page-Based vs. Keyset / Cursor Pagination:**
   *"If a new project is published or closed in real-time while a teen is scrolling from page 1 to page 2, offset-based pagination (`page * 20`) can produce duplicate or skipped items at page boundaries. Is there a cursor-based endpoint (e.g., `starting_after=projectId`) available in production?"*
2. **Offline-First Persistence:**
   *"Should project feeds be cached locally (e.g., using Hive or drift/sqflite) so teens on spotty 2G/3G connections can browse previously loaded projects offline without seeing an initial load failure?"*

---

## Part 3: Production Rollout Scenario

### Assumptions Made:
1. **Rollout Cohort:** Assumed standard Google Play Console staged rollout behavior where clicking "Halt" stops serving `v6.4.0` to new users, freezing adoption at 20% while we patch the issue.
2. **Crash Context:** Assumed `PlatformException` originates from native Android method channel invocation during Activity resume lifecycle.

### Questions I Would Ask the Team:
1. **Crashlytics Custom Keys:**
   *"Do we log custom keys in Crashlytics indicating which ad network (e.g., AdMob, Unity, AppLovin) was initialized and the exact Activity lifecycle state (`onStart`, `onResume`, `onWindowFocusChanged`)?"*
2. **Ad SDK Remote Kill-Switches:**
   *"Do we currently have any active Firebase Remote Config flags or LaunchDarkly toggles mapped to the ad integration layer, or is ad initialization hardcoded in native `MainActivity`?"*
