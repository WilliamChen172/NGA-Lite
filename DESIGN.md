# NGA Forum iOS Client — Design Document

**Version:** 2.3  
**Last Updated:** 2026-03-11  
**Status:** Living Document — all future work and changes should follow this guideline.

---

## 1. Executive Summary

The NGA Forum iOS Client is a third-party native iOS application for the NGA gaming forum (ngabbs.com / bbs.nga.cn). It provides forum browsing, thread reading, and posting via the unofficial NGA API. This document defines architecture, implementation guidelines, security requirements, scaling considerations, and risk mitigation for current and future development.

---

## 2. Architecture Overview

### 2.1 Layered Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                        │
│  SwiftUI Views │ ViewModels (@MainActor) │ Components             │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
┌──────────────────────────────────▼──────────────────────────────┐
│                         Business Layer                            │
│  AuthService │ ForumService (via ForumServiceProtocol)            │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
┌──────────────────────────────────▼──────────────────────────────┐
│                         Infrastructure Layer                      │
│  APIClient (Actor) │ KeychainService │ Request Builder            │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
┌──────────────────────────────────▼──────────────────────────────┐
│                         External APIs                             │
│  NGA API (bbs.nga.cn)                                             │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Separation of concerns** | Views render UI only; ViewModels hold state and orchestrate; Services perform data operations. |
| **Dependency injection** | Services exposed via protocols; ViewModels accept injected dependencies (e.g. `ForumServiceProtocol`). |
| **Single source of truth** | No duplicated state; auth flows through `AuthService`; data flows from services to ViewModels. |
| **Testability** | Protocols enable mocking; `MockForumService` for previews and unit tests. |
| **Thread safety** | Use Swift actors for network/auth services; `@MainActor` for UI-facing logic. |
| **Optional authentication** | Login is optional; browsing is public. Auth required only for write operations (post, reply). |

### 2.3 Project Structure

```
NGA/
├── App/                    # App entry point only
│   └── NGAApp.swift
├── Core/Theme/             # Design tokens (colors, layout)
├── Mocks/                  # Mock data and services for testing
├── Models/                 # Codable domain models
├── Services/               # API, auth, forum services + protocols
├── Utils/                  # Constants, errors, helpers (incl. TimeFormatter)
├── ViewModels/             # @MainActor ObservableObject per screen
└── Views/
    ├── Root/               # Main tab bar and home tab
    │   ├── MainTabView.swift
    │   └── HomeView.swift
    ├── Auth/               # Login and auth flows
    │   └── LoginView.swift
    ├── Forum/              # Forum browsing, threads
    │   ├── ForumListView.swift
    │   ├── ThreadListView.swift
    │   └── ThreadDetailView.swift
    ├── Profile/            # User profile
    │   ├── ProfileView.swift
    │   └── NotificationsView.swift
    ├── Post/               # Post composition
    │   └── ReplyView.swift
    └── Components/         # Reusable UI by domain
        ├── Common/         # ErrorStateView, LoadableView
        ├── Forum/          # ForumCard
        ├── Thread/         # ThreadRowView, TabButton
        └── Post/           # PostDetailView, PostRowView, PostActionButton
```

**View placement guidelines:**
- **Screen-level views** go in feature folders (Auth, Forum, Profile, Post).
- **Reusable components** go in `Components/` under the domain subfolder (Forum, Thread, Post) or `Common/` for generic UI.

---

## 3. Authentication Flow

### 3.1 Optional Authentication Model

**Design Decision:** The app uses an **optional authentication** model where users can browse content without logging in, but must authenticate to perform write operations.

| Action | Requires Auth | Experience |
|--------|---------------|------------|
| Browse forums | ❌ No | Direct access |
| View threads | ❌ No | Direct access |
| Read posts | ❌ No | Direct access |
| Search | ❌ No | Direct access |
| Reply to post | ✅ Yes | Login prompt → Reply |
| Create thread | ✅ Yes | Login prompt → Create |
| View profile | ✅ Yes | Login prompt displayed |
| Access notifications | ✅ Yes | Requires logged-in user |

### 3.2 Implementation Guidelines

**App Entry:**
```swift
// NGAApp.swift
var body: some Scene {
    WindowGroup {
        MainTabView()
            .environmentObject(authService)
            .task {
                await authService.restoreSession()
            }
    }
}
```

**Key points:**
- App always shows `MainTabView` (no login wall).
- `AuthService` attempts to restore session on launch.
- If token exists, user is silently authenticated.
- If no token, user browses as guest until they need to perform a write action.

**Login Prompts:**
When a user attempts an authenticated action:

```swift
// Example in ThreadDetailView
Button {
    if authService.isAuthenticated {
        showReplySheet = true
    } else {
        showLoginSheet = true  // Prompt to login
    }
} label: {
    Image(systemName: "square.and.pencil")
}
.sheet(isPresented: $showLoginSheet) {
    NavigationStack {
        LoginView(authService: authService)
    }
}
```

**Profile Tab Handling:**
```swift
// ProfileView shows login prompt if not authenticated
if authService.isAuthenticated {
    // Show user profile, settings, history
} else {
    // Show prominent login button
    loginPromptSection
}
```

### 3.3 Session Management

| Event | Behavior |
|-------|----------|
| **First launch** | No token → guest mode; auth state = false |
| **Successful login** | Save token to Keychain; set auth state = true; dismiss login sheet |
| **App restart** | Restore token from Keychain; set auth state = true if token exists |
| **Logout** | Clear token from Keychain; clear WKWebView NGA cookies; set auth state = false |
| **Token expiry** | API returns 401 → clear token; show login prompt on next authenticated action |

**WebView 登录：** 因 NGA 需图形验证码，登录入口使用 WebView 加载官方页面。流程、edge case 及后续适配见 [WEBVIEW_LOGIN.md](WEBVIEW_LOGIN.md)。

**登录后功能（Profile、消息、pendingAction）：** 状态、占位项、edge case 及后续计划见 [AUTH_AND_PROFILE_PLAN.md](AUTH_AND_PROFILE_PLAN.md)。

### 3.4 User Experience Principles

1. **Friction-free browsing:** Never block content viewing with login requirements.
2. **Just-in-time authentication:** Only prompt for login when user initiates an action that requires it.
3. **Clear value proposition:** When prompting login, explain what action requires it (e.g., "Login to reply").
4. **Preserve intent:** After login, automatically proceed with the intended action (e.g., open reply sheet).
5. **Graceful degradation:** If user cancels login, return to previous state without data loss.

**Future enhancement:** Remember user's intended action and auto-trigger after successful login:
```swift
@Published var pendingAction: PendingAction?

enum PendingAction {
    case replyToThread(threadId: Int)
    case createThread(forumId: Int)
}

// After login success:
if let action = pendingAction {
    handlePendingAction(action)
    pendingAction = nil
}
```

---

## 4. Implementation Guidelines

### 4.1 Adding New Features

1. **Define the API contract** — Check NGA API docs for endpoints, params, and response shapes.
2. **Extend models** — Add/update Codable structs in `Models/` with `CodingKeys` if needed.
3. **Extend `Endpoint`** — Add new cases and wire `lib`, `act`, `requiresPost`.
4. **Extend service protocol** — Add methods to `ForumServiceProtocol`; implement in `ForumService` and `MockForumService`.
5. **Create ViewModel** — Add `@MainActor` ViewModel with injected service.
6. **Create View** — Use `LoadableView` for loading/error states; follow `AppTheme` for styling.

### 4.2 Styling and Theming

- All colors, spacing, and layout constants live in **`AppTheme`**.
- Do not hardcode `Color(...)` or magic numbers in views.
- Add new design tokens to `AppTheme.Colors` or `AppTheme.Layout` as needed.

### 4.3 Error Handling

- Use `AppError` enum for all domain errors.
- Services throw; ViewModels catch and set `errorMessage`.
- Views display errors via `ErrorStateView` or `LoadableView`; always provide a retry path.
- Never swallow errors silently; log for debugging where appropriate.

### 4.4 Concurrency

- **Actors** for `APIClient`, `ForumService` (and any shared mutable state).
- **`@MainActor`** for ViewModels and views.
- Use `Task { await ... }` when calling actor methods from non-async contexts.
- Avoid capturing `self` in escaping closures without `[weak self]` or structured concurrency.

---

## 4. Difficulties and Hardships

### 4.1 Third-Party API Limitations

| Challenge | Impact | Mitigation |
|-----------|--------|------------|
| **Unofficial API** | No SLA, schema changes, or formal support. | Defensive parsing; flexible `Codable` with optional fields; handle decode failures gracefully. |
| **Auth mechanism** | `app_id` and `appSecret` may be undocumented or rotated. | Keep auth config in one place; support configurable credentials; document how to obtain/update. |
| **Response format variance** | API may return different structures (nested, flat, varying keys). | Use `APIResponse` wrappers; support multiple decode paths (`result`, `data`, `threads`). |
| **Rate limiting** | Unknown; may throttle or block clients. | Respect `Retry-After`; add jitter/backoff; cache frequently accessed data (e.g. forum list). |

### 4.2 HTML Content

- Post bodies contain HTML (links, images, formatting).
- **MVP:** Strip to plain text via SwiftSoup.
- **Future:** Consider `AttributedString`, WKWebView, or a safe HTML subset renderer.
- **Security:** Sanitize before rendering; guard against XSS if ever rendering raw HTML.

### 4.3 Legal and Platform Risk

- Third-party client; NGA may issue C&D or change API to block clients.
- App Store review may reject if perceived as unofficial or policy-violating.
- **Mitigation:** Clear “third-party” labeling; privacy policy; avoid NGA branding; be prepared to unpublish or pivot.

### 4.4 Offline and Edge Cases

- Network interruptions during write operations (post, reply).
- **Guideline:** Show clear error; allow retry; avoid double-posting by disabling submit until completion.
- **Future:** Queue drafts locally; sync when online (requires careful conflict handling).

---

## 5. Scaling Considerations

### 5.1 Client-Side Scaling

| Dimension | Approach |
|-----------|----------|
| **Data volume** | Paginate all lists (threads, posts); load more on scroll; cap in-memory cache size. |
| **Image loading** | Use Kingfisher (or similar) for avatars and inline images; enable disk/memory cache. |
| **Memory** | Avoid retaining large HTML strings; stream or chunk where feasible. |
| **UI performance** | Use `LazyVStack`/`LazyVGrid`; minimize work in view body; profile with Instruments. |

### 5.2 Caching Strategy

| Data Type | Cache Location | TTL / Invalidation |
|-----------|----------------|-------------------|
| Auth token | Keychain | Until logout or expiry |
| Forum list | In-memory (optional) | Session or 5–10 min |
| Thread list | In-memory per forum | On pull-to-refresh |
| Post content | None (MVP) | — |
| Images | Kingfisher cache | Per library defaults |

**Future:** Consider SwiftData or Core Data for offline forum/thread cache with background sync.

### 5.3 API Request Efficiency

- Batch where API supports it.
- Debounce search and similar user-triggered requests.
- Avoid redundant calls (e.g. forum list once per session).
- Use `URLSession` configuration (timeouts, caching policy) appropriate for API behavior.

---

## 6. Data Security

### 6.1 Credential Storage

| Requirement | Implementation |
|-------------|----------------|
| **Auth tokens** | Keychain only, via `KeychainService`. Never UserDefaults or plain files. |
| **Passwords** | Never persist. Transmit only over HTTPS; clear from memory after login. |
| **Sensitive config** | Avoid hardcoding `appSecret` in source; use build config or secure backend if possible. |

### 6.2 Network Security

| Requirement | Implementation |
|-------------|----------------|
| **HTTPS only** | All API calls over `https://`. No `http://` or mixed content. |
| **Certificate validation** | Use default `URLSession` (no custom `URLSessionDelegate` that disables pinning unless justified). |
| **Request signing** | Follow NGA `clientSign` (MD5) for login; keep implementation in one place. |
| **Headers** | Avoid logging auth headers; strip tokens from error messages shown to users. |

### 6.3 Data Handling

| Data | Handling |
|------|----------|
| **User content** | Treat as untrusted; sanitize before display or storage. |
| **API responses** | Validate structure; fail closed on unexpected data. |
| **Logs** | Never log tokens, passwords, or PII. Use redaction if logging request/response metadata. |
| **Clipboard** | Avoid auto-copying sensitive data; be mindful of pasteboards. |

### 6.4 Keychain Configuration

- Use a dedicated Keychain service identifier (`Constants.Keychain.serviceName`).
- Consider `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for token items.
- On logout, explicitly delete all stored credentials.

---

## 7. State Management and Data Flow

### 7.1 State Ownership Rules

| Component | State Type | Ownership | Rationale |
|-----------|-----------|-----------|-----------|
| **View** | `@State` for UI-only state | Local (e.g., sheet presentation, animation) | Ephemeral UI state that doesn't need to persist across view recreations. |
| **ViewModel** | `@Published` for domain state | Owned by ViewModel, observed by View | Business logic state (data, loading, errors) belongs in ViewModel. |
| **Service (Actor)** | Private mutable state | Encapsulated in actor | Thread-safe shared state (auth token, cache). |
| **Singleton** | App-level global state | `AuthService.shared` only | Auth is truly global; avoid singleton pattern elsewhere. |

### 7.2 Navigation State

**Current:** Using SwiftUI's `NavigationStack` with value-based navigation.

**Guidelines:**
- Keep navigation state in the View layer (not ViewModel).
- Use `navigationDestination(for:)` with model types as navigation values.
- For complex flows (onboarding, multi-step forms), consider a coordinator pattern or navigation stack management.

**Future consideration:** If navigation becomes complex, extract to a `@Observable` router/coordinator that ViewModels can trigger programmatically.

### 7.3 Avoiding Common Pitfalls

| Anti-Pattern | Why It's Bad | Solution |
|--------------|--------------|----------|
| ViewModel retaining View references | Breaks unidirectional data flow; memory leaks | View observes ViewModel; ViewModel never knows about View. |
| View calling Service directly | Bypasses business logic; hard to test | Always route through ViewModel. |
| Nested @StateObject creation | Creates new instances on view updates | Hoist to parent or use @ObservedObject for passed-in ViewModels. |
| Actor reentrancy assumptions | Data races if not careful with suspended state | Use `isolated` parameters; avoid assumptions about actor state across `await` boundaries. |

---

## 8. Performance Optimization

### 8.1 View Performance

| Technique | Application | Priority |
|-----------|-------------|----------|
| **Lazy loading** | Use `LazyVStack`/`LazyHStack` for long lists | High (already used in thread/post lists) |
| **View identity** | Explicit `id()` modifiers when ForEach identity isn't obvious | Medium |
| **Expensive computations** | Move to ViewModel; cache results; use `@State` for derived values sparingly | Medium |
| **Conditional rendering** | Prefer `if-else` over opacity/hidden when structure changes | Low |

### 8.2 Network Optimization

**Current state:** Basic pagination implemented.

**Improvements:**
- **Prefetching:** Load page N+1 when user reaches 80% of page N (not 100%).
- **Deduplication:** Track in-flight requests; cancel/ignore duplicate calls (e.g., rapid refresh).
- **Request coalescing:** Batch multiple reads if API supports it.
- **Timeout strategy:** 
  - Read operations: 30s timeout
  - Write operations: 60s timeout (posting may be slower)
  - Login/auth: 15s timeout

**Implementation note:** Add request tracking in `APIClient` actor to prevent duplicate requests:

```swift
// In APIClient actor
private var inflightRequests: [String: Task<Data, Error>] = [:]
```

### 8.3 Memory Management

| Risk Area | Mitigation |
|-----------|------------|
| **Large HTML strings** | Parse and extract text immediately; discard HTML after processing. |
| **Image caching** | Use third-party library (Kingfisher, SDWebImage) with size limits. |
| **Pagination accumulation** | Cap maximum items in ViewModel arrays (e.g., 500 posts); implement virtual scrolling or paging windows. |
| **Codable decoding** | Stream large responses where possible; consider using `JSONSerialization` for selective parsing. |

### 8.4 Monitoring and Metrics

**Recommended instrumentation:**
- Log network request duration (95th percentile) for performance regression detection.
- Track memory usage in ViewModels (especially for thread detail with hundreds of posts).
- Monitor decode failures by endpoint (indicates API changes).
- Count retry attempts per user session (indicates network/API stability issues).

**Tools:**
- Instruments (Time Profiler, Allocations, Network)
- MetricKit for production metrics (crash rates, hang rates, battery impact)
- Custom Analytics (optional): Track feature usage, error rates

---

## 9. Accessibility

### 9.1 Required Support

| Feature | Implementation | Status |
|---------|----------------|--------|
| **VoiceOver** | Semantic labels for all interactive elements | 🔴 TODO |
| **Dynamic Type** | Respect user font size preferences; avoid fixed heights | 🔴 TODO |
| **Color contrast** | WCAG AA minimum (4.5:1 for text) | 🟡 Verify |
| **Reduced motion** | Honor `@Environment(\.accessibilityReduceMotion)` | 🔴 TODO |
| **Touch targets** | Minimum 44×44 pt per HIG | 🟡 Verify |

### 9.2 Implementation Guidelines

**VoiceOver:**
- Add `.accessibilityLabel()` to images, icons, and non-text controls.
- Use `.accessibilityValue()` for dynamic content (e.g., reply count).
- Group related elements with `.accessibilityElement(children: .combine)`.
- Add `.accessibilityAction()` for contextual actions (e.g., swipe actions).

**Dynamic Type:**
```swift
Text("Thread Title")
    .font(.headline)  // ✅ Scales with Dynamic Type
    .lineLimit(2)     // ✅ Allow wrapping

// ❌ Avoid:
.font(.system(size: 16))  // Fixed size
.frame(height: 50)        // Fixed height that won't accommodate larger text
```

**Keyboard navigation (Mac Catalyst/iPad):**
- Ensure tab order is logical.
- Support arrow key navigation in lists.
- Add keyboard shortcuts for common actions (⌘N for new thread, ⌘R for reply).

---

## 10. Localization (Future)

### 10.1 String Management

**Current:** English only, hardcoded strings.

**Future plan:**
1. Extract all user-facing strings to `Localizable.strings`.
2. Use `NSLocalizedString()` or SwiftUI's `Text("key")` with string catalog.
3. Support at minimum: English, Simplified Chinese (forum is Chinese).
4. Use `stringsdict` for plurals (e.g., "1 reply" vs "5 replies").

### 10.2 Non-Text Considerations

- Date/time formatting via `Date.FormatStyle` (respects locale).
- Number formatting (reply counts, page numbers).
- Text direction (LTR/RTL) — less critical for Chinese/English but good practice.
- Images with embedded text should have localized variants.

---

## 11. Testing Guidelines

### 11.1 Unit Testing

**ViewModel tests:**
```swift
@Test("ThreadListViewModel loads threads successfully")
func testLoadThreadsSuccess() async throws {
    let mockService = MockForumService()
    mockService.threadsToReturn = [/* test data */]
    
    let viewModel = ThreadListViewModel(forumService: mockService)
    await viewModel.loadThreads(forumId: 1)
    
    #expect(viewModel.threads.count == mockService.threadsToReturn.count)
    #expect(viewModel.isLoading == false)
    #expect(viewModel.errorMessage == nil)
}

@Test("ThreadListViewModel handles errors")
func testLoadThreadsError() async throws {
    let mockService = MockForumService()
    mockService.shouldThrowError = true
    
    let viewModel = ThreadListViewModel(forumService: mockService)
    await viewModel.loadThreads(forumId: 1)
    
    #expect(viewModel.threads.isEmpty)
    #expect(viewModel.errorMessage != nil)
}
```

**Service tests:**
- Mock `URLSession` using custom `URLProtocol`.
- Test endpoint construction, parameter encoding, response parsing.
- Test error handling (401, 500, network timeout, malformed JSON).

**Model tests:**
- Test `Codable` conformance with real API response samples.
- Test edge cases (missing optional fields, unexpected values).

### 11.2 Integration Testing

- Test full flow: ViewModel → Service → APIClient → MockURLSession.
- Verify auth token propagation from login through authenticated requests.
- Test pagination logic (load more, deduplication, end of list).

### 11.3 UI Testing

**Critical paths:**
1. Login → Forum list → Thread list → Post detail
2. Create new thread with validation
3. Reply to post with error recovery
4. Logout and session cleanup

**Use Preview providers for manual UI testing:**
```swift
#Preview("Thread List - Loading") {
    let viewModel = ThreadListViewModel(forumService: MockForumService())
    viewModel.isLoading = true
    return ThreadListView(forum: .sample, viewModel: viewModel)
}

#Preview("Thread List - Error") {
    let viewModel = ThreadListViewModel(forumService: MockForumService())
    viewModel.errorMessage = "Network connection failed"
    return ThreadListView(forum: .sample, viewModel: viewModel)
}
```

### 11.4 Manual Testing Checklist

- [ ] Auth flow (login success, login failure, logout, session restore)
- [ ] Pagination (scroll to end, load more, network failure mid-load)
- [ ] Pull-to-refresh on all list views
- [ ] Error states with retry (network error, auth error, decode error)
- [ ] Offline behavior (airplane mode, spotty connection)
- [ ] Post creation (success, validation errors, network timeout)
- [ ] Deep navigation (forum → thread → post, back navigation state preservation)
- [ ] Memory usage during long scrolling sessions
- [ ] App backgrounding/foregrounding during network requests

---

## 12. Error Recovery Strategies

### 12.1 Network Error Types and Handling

| Error Type | User Experience | Technical Recovery |
|------------|-----------------|-------------------|
| **Timeout** | "Connection timed out. Please try again." | Retry with exponential backoff (1s, 2s, 4s). |
| **401 Unauthorized** | Auto-redirect to login; preserve navigation state. | Clear token, set `isAuthenticated = false`. |
| **403 Forbidden** | "You don't have permission to access this." | No retry; show contact support. |
| **404 Not Found** | "Content not found. It may have been deleted." | No retry; allow navigation back. |
| **5xx Server Error** | "Server error. Please try again later." | Retry once after 5s; if fails, show error. |
| **Decode Failure** | "Unable to load content." (log details) | Retry once (may be transient); report to developer. |
| **No Connection** | "No internet connection. Please check your network." | Wait for network to return; auto-retry when available. |

### 12.2 Retry Logic

**In ViewModel:**
```swift
func loadThreads(forumId: Int, retryCount: Int = 0) async {
    isLoading = true
    errorMessage = nil
    
    do {
        threads = try await forumService.getThreads(forumId: forumId, page: 1)
    } catch let error as AppError {
        if retryCount < 1, case .networkError = error {
            try? await Task.sleep(for: .seconds(2))
            await loadThreads(forumId: forumId, retryCount: retryCount + 1)
        } else {
            errorMessage = error.errorDescription
        }
    }
    
    isLoading = false
}
```

**Network reachability:**
- Use `Network` framework's `NWPathMonitor` to detect connectivity changes.
- Show banner when offline; auto-retry pending requests when online.
- Cache last successful response for graceful degradation.

### 12.3 Partial Failure Handling

**Scenario:** Loading 50 posts, but 3 have malformed content.

**Current:** Entire decode fails.

**Improvement:** Use lenient decoding:
```swift
struct ThreadListResponse: Decodable {
    let threads: [ForumThread]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode array, skipping invalid items
        var threadsArray = try container.nestedUnkeyedContainer(forKey: .threads)
        var threads: [ForumThread] = []
        
        while !threadsArray.isAtEnd {
            if let thread = try? threadsArray.decode(ForumThread.self) {
                threads.append(thread)
            } else {
                _ = try? threadsArray.decode(AnyCodable.self) // Skip invalid item
            }
        }
        
        self.threads = threads
    }
}
```

---

## 13. Privacy and App Store Compliance

### 13.1 Privacy Manifest (Required for App Store)

**Must include `PrivacyInfo.xcprivacy`:**
- Declare data collection practices (user content, identifiers, etc.).
- List third-party SDKs and their purposes.
- Declare "required reason" APIs if using (e.g., UserDefaults, file timestamps).

### 13.2 Data Usage Declaration

| Data Type | Collected? | Purpose | Linked to User? |
|-----------|-----------|---------|-----------------|
| User content (posts, threads) | Yes | App functionality | Yes |
| User credentials | Transmitted only (not stored except token) | Authentication | Yes |
| Device ID | No | — | — |
| Analytics/Crash data | Recommended | App improvement | No (anonymized) |

### 13.3 Third-Party Content Moderation

**Risk:** User-generated content may violate App Store guidelines (hate speech, adult content, etc.).

**Mitigation:**
- Add in-app reporting mechanism for inappropriate content.
- Include "Report" button on posts/threads.
- Comply with takedown requests promptly.
- Consider age-rating based on forum content (likely 17+).

### 13.4 Legal Disclaimers

**In-app and App Store description:**
- "This is an unofficial third-party client for NGA Forum."
- "Not affiliated with or endorsed by NGA."
- Link to privacy policy and terms of use.
- Clear copyright notices (content belongs to NGA and respective authors).

---

## 14. Deployment and Release Management

### 14.1 Build Configurations

| Configuration | Purpose | Settings |
|---------------|---------|----------|
| **Debug** | Development | Verbose logging, mock services enabled, no obfuscation |
| **Beta** | TestFlight | Moderate logging, real API, crash reporting, analytics |
| **Release** | App Store | Minimal logging (errors only), optimizations, obfuscation |

### 14.2 Version Management

**Scheme:**
- Follow semantic versioning: `MAJOR.MINOR.PATCH` (e.g., 1.2.3)
- `MAJOR`: Breaking changes or major feature sets
- `MINOR`: New features, backward-compatible
- `PATCH`: Bug fixes only

**Build numbers:** Auto-increment via CI/CD or `agvtool`.

### 14.3 Release Checklist

- [ ] All tests pass (unit, integration, UI)
- [ ] Manual testing on physical devices (iPhone, iPad, various iOS versions)
- [ ] Accessibility audit (VoiceOver, Dynamic Type)
- [ ] Performance profiling (Instruments)
- [ ] Update CHANGELOG.md with user-facing changes
- [ ] App Store screenshots and metadata updated
- [ ] Privacy manifest up to date
- [ ] TestFlight beta feedback addressed
- [ ] Submit for App Review with clear review notes (especially for third-party client)

### 14.4 Rollout Strategy

1. **Internal testing:** Developers and QA
2. **TestFlight beta:** 50–100 users for 1–2 weeks
3. **Phased release:** 10% → 50% → 100% over 1 week (if App Store supports, or manual timing)
4. **Monitor:** Crash rates, user reviews, support requests
5. **Hotfix process:** Critical bugs get emergency patch within 24h

---

## 15. Future Architecture Considerations

### 15.1 Offline Support

**Current:** No offline capability; all data fetched on demand.

**Future:**
- **Local persistence:** SwiftData or Core Data for caching forums, threads, and read posts.
- **Draft queue:** Save unsent posts/replies locally; sync when online.
- **Conflict resolution:** If post fails to send, allow user to retry or edit.

**Challenges:**
- Sync complexity (what if thread is deleted while offline?).
- Storage limits (how much to cache?).
- Data staleness (cache invalidation strategy).

### 15.2 Real-Time Updates

**Current:** Pull-to-refresh only.

**Future:**
- WebSocket or long-polling for new post notifications.
- Push notifications for replies to user's threads (requires backend support or polling).
- Live activity updates (e.g., watching a thread for new posts).

**Challenges:**
- NGA API may not support WebSockets.
- Battery impact of constant polling.
- Background execution limits on iOS.

### 15.3 Rich Content Rendering

**Current:** HTML stripped to plain text.

**Future:**
- Render styled text using `AttributedString` with Markdown-like formatting.
- Embed images inline (UIKit: `WKWebView`; SwiftUI: `AsyncImage` with HTML parsing).
- Support video embeds, code blocks, quotes, mentions.

**Challenges:**
- Security (sanitizing HTML to prevent XSS).
- Performance (rendering heavy HTML in scrolling lists).
- Maintainability (HTML parsing is fragile).

### 15.4 Modularization

**Current:** Monolithic app target.

**Future:** Split into frameworks for better build times and testability:
```
NGA/
├── NGACore.framework          # Models, protocols, utilities
├── NGANetworking.framework    # APIClient, services
├── NGAUI.framework            # Reusable views, components
└── NGA (app target)           # App entry, screens, ViewModels
```

**Benefits:**
- Parallel builds
- Enforced dependency boundaries
- Framework-level testing
- Potential for App Clip or widget extensions

### 15.5 Design System Evolution

**Current:** `AppTheme` with basic tokens.

**Future:**
- **Component library:** Catalog of reusable components with variants (primary button, secondary button, destructive button, etc.).
- **Dark mode refinement:** Custom colors that look good in both modes.
- **Liquid Glass adoption:** Modern Apple design language (blur effects, depth).
- **Animation system:** Consistent spring curves, durations, easing functions.

---

## 16. Monitoring and Observability

### 16.1 Logging Strategy

**Log levels:**
```swift
enum LogLevel {
    case debug   // Verbose info for development only
    case info    // General informational messages
    case warning // Potential issues that don't break functionality
    case error   // Errors that affect user experience
    case fatal   // Critical errors requiring immediate attention
}
```

**What to log:**
- API request/response metadata (endpoint, duration, status code) — **not** auth tokens
- Decode failures with context (endpoint, sample of raw data)
- User actions (login, post creation, navigation) for flow analysis
- Performance markers (view load time, pagination trigger)

**What NOT to log:**
- Passwords, tokens, or other credentials
- Full API response bodies (may contain PII)
- User-generated content (privacy concern)

### 16.2 Crash Reporting

**Recommended:** Integrate a crash reporting SDK (e.g., Firebase Crashlytics, Sentry).

**Custom crash context:**
```swift
// Set user context on login
Crashlytics.setUserID(user.uid)
Crashlytics.setCustomValue(user.username, forKey: "username")

// Add breadcrumbs for navigation
Crashlytics.log("Navigated to forum: \(forum.name)")
```

### 16.3 Analytics

**Key metrics to track:**
- User engagement: Daily/weekly active users, session duration
- Feature usage: Forum views, thread reads, posts created
- Performance: Screen load times, API response times
- Errors: API error rate, decode failure rate, login failure rate

**Privacy-preserving approach:**
- Anonymize user IDs
- Aggregate data (e.g., "90% of users browse forums daily")
- Allow users to opt out

---

## 17. Code Quality Standards

### 17.1 Swift Style Guidelines

**Follow:**
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Naming conventions: `lowerCamelCase` for variables/functions, `UpperCamelCase` for types
- Max line length: 120 characters (enforced by SwiftLint)
- Prefer `let` over `var` (immutability by default)

**Formatting:**
- 4-space indentation (no tabs)
- Opening braces on same line: `func foo() {`
- Vertical alignment for readability (e.g., aligning enum cases)

### 17.2 Code Review Checklist

**For reviewers:**
- [ ] Does this follow the architecture (layers, protocols, DI)?
- [ ] Are errors handled appropriately?
- [ ] Is there test coverage for new logic?
- [ ] Are there potential retain cycles or memory leaks?
- [ ] Is sensitive data (tokens, passwords) handled securely?
- [ ] Are strings localized (or TODO added for future)?
- [ ] Are accessibility labels/hints provided for new UI?
- [ ] Does this introduce any new dependencies? Are they justified?

### 17.3 Documentation Standards

**Required for:**
- Public APIs (protocols, service methods)
- Complex algorithms or business logic
- Non-obvious workarounds or hacks

**Format:**
```swift
/// Loads threads for the specified forum with pagination support.
///
/// - Parameters:
///   - forumId: The unique identifier of the forum.
///   - page: The page number to load (1-indexed).
/// - Returns: An array of `ForumThread` objects.
/// - Throws: `AppError` if the request fails or decoding fails.
func getThreads(forumId: Int, page: Int) async throws -> [ForumThread]
```

### 17.4 Static Analysis Tools

**Recommended:**
- **SwiftLint:** Enforce style and catch common issues (unused code, force unwraps, etc.)
- **Swift Format:** Auto-format code for consistency
- **SonarQube or similar:** For complexity analysis, code smells, security vulnerabilities

**Critical rules:**
- No force-unwrapping (`!`) without documented justification
- No force-try (`try!`) except in truly safe contexts (e.g., static JSON decoding in tests)
- No `fatalError()` in production code paths
- Limit cyclomatic complexity (max 10 per function)

---

## 18. Change Management

When modifying this design:

1. Update the **Last Updated** date at the top.
2. Increment the version number for significant architectural changes.
3. Add a detailed changelog entry at the end of the document.
4. Ensure all code changes align with updated guidelines.
5. If security, scaling, or testing assumptions change, revisit relevant sections.
6. Communicate changes to the team via commit message, PR description, or team meeting.

---

## 19. References

- [NGA API Documents](https://github.com/wolfcon/NGA-API-Documents/)
- [NGA Forum](https://ngabbs.com)
- Apple [Secure Coding Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/SecureCodingGuide/)
- Apple [Data Protection](https://developer.apple.com/documentation/security/certificate_key_and_trust_services)
- Apple [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- Apple [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- Apple [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [WCAG 2.1 Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

## 20. Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-10 | Initial design document. Architecture, security, scaling, and implementation guidelines. |
| 2.0 | 2026-03-11 | **Major expansion:** Added sections on state management (§7), performance optimization (§8), accessibility (§9), localization (§10), comprehensive testing (§11), error recovery (§12), privacy compliance (§13), deployment (§14), future architecture (§15), monitoring (§16), code quality (§17). Enhanced existing sections with concrete examples and implementation notes. |
| 2.1 | 2026-03-11 | **Views/App reorganization:** Deleted duplicate files (AppNGAApp, ViewsMainTabView, ViewsThreadDetailView, etc.). Introduced hierarchical Views structure: Auth/, Forum/, Profile/, Post/ for screens; Components/Common/, Forum/, Thread/, Post/ for reusable UI. Moved TimeFormatter to Utils/. Updated §2.3 project structure. |
| 2.2 | 2026-03-11 | **App slim-down:** Moved MainTabView to Views/Root/, HomeView to Views/Home/. App/ now contains only NGAApp.swift (entry point). |
| 2.3 | 2026-03-11 | **Optional authentication model:** Changed from login-required to browse-first architecture. Users can now browse forums, threads, and posts without logging in. Login only required for write operations (reply, post, profile access). Added §3 Authentication Flow detailing implementation. Updated NGAApp.swift to remove login wall. Updated ProfileView and ThreadDetailView to show login prompts only when needed. Added NotificationsView to main tab. Moved Settings into Profile. Simplified HomeView header (removed user avatar/name, settings, and notification buttons). |
