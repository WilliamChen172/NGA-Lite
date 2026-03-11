# NGA Forum iOS Client — MVP Shipping Checklist

**Goal:** Ship a working app to TestFlight within 1-2 weeks  
**Philosophy:** Match reference design first, then add functionality  
**Target:** TestFlight Beta (not App Store yet)

---

## ✅ PHASE 1: UI Implementation (CURRENT - Days 1-3)

### 1. Thread List View ✅ COMPLETED
- [x] Tab bar with: 全部, 置顶, 热帖, 精华, 子版块
- [x] Thread rows with title
- [x] Author name + timestamp + reply count
- [x] Relative time formatting (5分钟前, 2小时前, etc.)
- [x] Clean list style matching reference
- [x] Pagination on scroll

### 2. Thread Detail View ✅ COMPLETED
- [x] Large thread title header
- [x] Author card with avatar placeholder
- [x] Author metadata (level, prestige, post count)
- [x] "关注" (Follow) button (UI only for MVP)
- [x] Post content display
- [x] Timestamp + device icon
- [x] Action bar: gift, like, dislike, reply, more
- [x] Multiple posts in scrollable list
- [x] Proper spacing and layout
- [x] Gray background (systemGroupedBackground)

### 3. Next UI Tasks (Priority Order)

**3a. Polish Thread List (1-2 hours)**
- [ ] Red text color for pinned/important threads
- [ ] Better empty state (when no threads)
- [ ] Loading skeleton (optional for MVP)

**3b. Polish Thread Detail (1-2 hours)**
- [ ] Floor number ("1楼", "2楼") on posts
- [ ] Collapsible sections for long posts ("点击展开...")
- [ ] Better avatar loading (async image)
- [ ] Inline emoji/image rendering (basic)

**3c. Forum List View (2-3 hours)**
- [ ] Forum icon/avatar
- [ ] Forum name + description
- [ ] Subforum count
- [ ] Match reference design style

---

## ✅ PHASE 2: Backend Integration (Days 4-5)

### 4. Verify API Integration
- [ ] Test thread loading with real API data
- [ ] Verify pagination works
- [ ] Test author data displays correctly
- [ ] Check timestamp formatting with real dates
- [ ] Verify reply count accuracy

### 5. Reply Functionality
- [x] ReplyView UI (already done)
- [x] ThreadDetailViewModel.createReply() (already done)
- [ ] Test posting actual reply to NGA
- [ ] Success confirmation message
- [ ] Error handling + retry

---

## ✅ PHASE 3: Critical Polish (Days 6-7)

### 6. Error Handling
- [ ] Network timeout shows error (not crash)
- [ ] Offline mode shows banner
- [ ] Retry button works everywhere
- [ ] Token expiry redirects to login

### 7. Physical Device Testing
- [ ] Login with real credentials
- [ ] Browse actual forums
- [ ] Read real threads
- [ ] Post a reply
- [ ] Kill app, relaunch (session persists)
- [ ] Logout (clears token)
- [ ] Test on iPhone (not just simulator)

---

### 3. Minimum Polish

- [ ] **App Icon** (can be simple placeholder)
  - [ ] 1024×1024 App Store icon
  - [ ] All sizes generated (use Xcode asset catalog)

- [ ] **Launch Screen**
  - [ ] Plain launch screen (logo or solid color)
  - [ ] No "Loading..." text (iOS HIG violation)

- [ ] **App Name**
  - [ ] Decide final name (avoid "NGA" trademark issues)
  - [ ] Suggestion: "NGA Reader" or "Forum for NGA"

- [ ] **Basic UI polish**
  - [ ] No placeholder text visible to users
  - [ ] Navigation titles are correct
  - [ ] Buttons have clear labels
  - [ ] Loading indicators show during network requests

---

### 4. Legal/Compliance (App Store will reject without these)

- [x] **HTTPS only** (verified - using `https://` in APIClient)

- [ ] **Privacy Manifest** (`PrivacyInfo.xcprivacy`)
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
      <key>NSPrivacyTracking</key>
      <false/>
      <key>NSPrivacyCollectedDataTypes</key>
      <array>
          <dict>
              <key>NSPrivacyCollectedDataType</key>
              <string>NSPrivacyCollectedDataTypeUserContent</string>
              <key>NSPrivacyCollectedDataTypeLinked</key>
              <true/>
              <key>NSPrivacyCollectedDataTypeTracking</key>
              <false/>
              <key>NSPrivacyCollectedDataTypePurposes</key>
              <array>
                  <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
              </array>
          </dict>
      </array>
      <key>NSPrivacyAccessedAPITypes</key>
      <array>
          <dict>
              <key>NSPrivacyAccessedAPIType</key>
              <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
              <key>NSPrivacyAccessedAPITypeReasons</key>
              <array>
                  <string>CA92.1</string>
              </array>
          </dict>
      </array>
  </dict>
  </plist>
  ```

- [ ] **App Store disclaimer text** (for App Store listing)
  ```
  This is an unofficial third-party client for NGA Forum. 
  Not affiliated with or endorsed by NGA.
  
  All content belongs to NGA and respective authors.
  ```

- [ ] **Age Rating** (likely 17+ due to user-generated content)

---

## 🟡 SHOULD HAVE (Important but not blocking)

### 5. Basic Error Recovery

- [ ] **Retry logic for network errors**
  - Implement 1 automatic retry for timeout/network errors
  - Show "Retry" button if fails

- [ ] **Token expiry handling**
  - If 401 Unauthorized, redirect to login
  - Don't lose user's place in navigation

### 6. User Experience

- [ ] **Empty states**
  - [ ] "No forums" (unlikely but handle it)
  - [ ] "No threads in this forum"
  - [ ] "No posts yet"

- [ ] **Pull-to-refresh everywhere**
  - [x] Thread list (done)
  - [x] Post list (done)
  - [ ] Forum list

---

## ❌ SKIP FOR MVP (Do later)

### 7. Deferred Features

- ❌ **Create new thread** (just reply for MVP)
- ❌ **User profile viewing**
- ❌ **Search** (threads, posts, users)
- ❌ **Bookmarks/Favorites**
- ❌ **Rich HTML rendering** (plain text is fine)
- ❌ **Image uploads**
- ❌ **Quote/mention features**
- ❌ **Dark mode customization** (system default is fine)
- ❌ **Settings screen** (just logout for now)
- ❌ **Accessibility VoiceOver labels** (do in v1.1)
- ❌ **Localization** (English only for MVP)
- ❌ **Offline caching**
- ❌ **Push notifications**

### 8. Deferred Polish

- ❌ **Custom fonts/advanced theming**
- ❌ **Animations/transitions**
- ❌ **Haptic feedback**
- ❌ **iPad optimization** (works but not polished)
- ❌ **Mac Catalyst**
- ❌ **Landscape mode optimization**

---

## 📋 Testing Checklist (Before TestFlight)

### Manual Testing (30 min)

1. **Fresh Install Flow**
   - [ ] Delete app, reinstall
   - [ ] Login works
   - [ ] Browse forums → threads → posts
   - [ ] Reply to a thread
   - [ ] Kill app, reopen (session restored?)
   - [ ] Logout, login again

2. **Error Scenarios**
   - [ ] Turn on Airplane Mode → try to load → see error message
   - [ ] Turn off Airplane Mode → tap Retry → works
   - [ ] Enter wrong password → see error → can retry
   - [ ] Scroll to end of thread list → pagination loads

3. **Edge Cases**
   - [ ] Very long thread title (does it wrap?)
   - [ ] Post with no author (does it crash?)
   - [ ] Forum with no threads (empty state shows?)

---

## 🚀 Launch Sequence (2-5 days)

### Day 1: Finish Reply Feature
**Priority: CRITICAL**

```swift
// Already have ThreadDetailViewModel.createReply()
// Need to add ReplyView UI:

// 1. Add reply button to ThreadDetailView
// 2. Show sheet with text editor
// 3. Call viewModel.createReply()
// 4. Show success/error
// 5. Refresh post list on success
```

**Estimate:** 2-4 hours

---

### Day 2: Testing & Bug Fixes

- [ ] Test on physical device (all scenarios above)
- [ ] Fix any crashes found
- [ ] Fix any UI issues found
- [ ] Verify logout clears token

**Estimate:** 3-5 hours

---

### Day 3: Polish & Compliance

- [ ] Add app icon (even a simple one)
- [ ] Add launch screen
- [ ] Add Privacy Manifest file
- [ ] Write App Store description text
- [ ] Take screenshots (iPhone 6.7" required)

**Estimate:** 2-3 hours

---

### Day 4: TestFlight Submission

1. **Xcode setup**
   - [ ] Set version to 1.0.0 (build 1)
   - [ ] Configure signing (Team, Bundle ID)
   - [ ] Archive build

2. **App Store Connect**
   - [ ] Create app listing
   - [ ] Upload build
   - [ ] Add test notes: "Unofficial NGA forum client. Login requires NGA account."
   - [ ] Submit for TestFlight review (usually 1-2 hours)

3. **Internal testing**
   - [ ] Install on your device via TestFlight
   - [ ] Test one more time

**Estimate:** 1-2 hours (plus waiting for review)

---

### Day 5: Beta Testing

- [ ] Invite 5-10 friends to TestFlight
- [ ] Collect feedback
- [ ] Fix critical bugs (if any)
- [ ] Push build 2 if needed

---

## 🎯 MVP Success Criteria

Your MVP is shippable when:

✅ User can log in  
✅ User can browse forums  
✅ User can read threads  
✅ User can reply to threads  
✅ No crashes during normal use  
✅ Privacy Manifest included  
✅ App icon present  
✅ TestFlight build installed and tested

**Everything else is a post-MVP feature.**

---

## 📊 Current Status Estimate

| Component | Status | Est. Time to Complete |
|-----------|--------|----------------------|
| Login/Auth | ✅ 100% | Done |
| Forum browsing | ✅ 100% | Done |
| Thread viewing | ✅ 100% | Done |
| Reply feature | 🟡 50% (backend done, UI missing) | 2-4 hours |
| Error handling | 🟡 70% | 1-2 hours |
| Testing | 🔴 0% | 3-5 hours |
| App icon | 🔴 0% | 30 min |
| Privacy Manifest | 🔴 0% | 30 min |
| TestFlight setup | 🔴 0% | 1-2 hours |

**Total remaining work: ~10-15 hours over 3-5 days**

---

## 🛠️ Quick Wins (Do Today)

### 1. Add Privacy Manifest (15 min)
File → New → File → App Privacy → Save as `PrivacyInfo.xcprivacy`

### 2. Add App Icon (30 min)
- Generate icon: https://www.appicon.co/
- Or use SF Symbol as placeholder: https://www.flaticon.com/

### 3. Implement Reply UI (2-4 hours)
See next section for code...

---

## 💻 Reply Feature Implementation

Since this is your biggest blocker, here's the code:

### Step 1: Update ReplyView.swift

```swift
import SwiftUI

struct ReplyView: View {
    let thread: ForumThread
    @ObservedObject var viewModel: ThreadDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var content = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $content)
                    .frame(minHeight: 200)
                    .padding()
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(8)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task { await sendReply() }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPosting)
                }
            }
            .disabled(viewModel.isPosting)
            .overlay {
                if viewModel.isPosting {
                    ProgressView("Sending...")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "Failed to send reply")
            }
        }
    }
    
    private func sendReply() async {
        do {
            try await viewModel.createReply(content: content, replyTo: nil)
            dismiss()
        } catch {
            showError = true
        }
    }
}
```

### Step 2: Update ThreadDetailView.swift

Add reply button to toolbar:

```swift
// In ThreadDetailView, add to body:
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button {
            showReplySheet = true
        } label: {
            Image(systemName: "square.and.pencil")
        }
    }
}
.sheet(isPresented: $showReplySheet) {
    ReplyView(thread: thread, viewModel: viewModel)
}

// Add state at top of ThreadDetailView:
@State private var showReplySheet = false
```

**Test it:** Run, navigate to a thread, tap pencil icon, type reply, send.

---

## 📞 When You're Stuck

**Problem:** "I don't know how to do X"  
**Solution:** Ship without X. Add in v1.1.

**Problem:** "This feature is buggy"  
**Solution:** Show error message, add to backlog.

**Problem:** "The UI looks bad"  
**Solution:** Good enough for TestFlight. Polish later.

**Remember:** MVP = Minimum **Viable** Product. Viable means it works, not that it's perfect.

---

## 🎉 Post-MVP Roadmap (v1.1, v1.2...)

Once MVP ships, prioritize by user feedback:

**v1.1 (Week 2-3):**
- Create new thread
- User profile viewing
- Better HTML rendering
- Accessibility labels

**v1.2 (Week 4-5):**
- Search functionality
- Bookmarks
- Settings screen

**v2.0 (Month 2-3):**
- Offline support
- Push notifications
- Rich media uploads

---

## ✅ Final Pre-Flight Checklist

Before submitting to TestFlight:

- [ ] Version number set (1.0.0 build 1)
- [ ] App icon present
- [ ] Privacy Manifest included
- [ ] No hardcoded test credentials in code
- [ ] No debug print statements logging sensitive data
- [ ] Tested on physical device
- [ ] Login works
- [ ] Reply works
- [ ] No crashes
- [ ] "Unofficial third-party client" in description

**You're ready to ship! 🚀**

---

**Questions? Stuck on something? Let me know what's blocking you and I'll help you ship this MVP ASAP.**
