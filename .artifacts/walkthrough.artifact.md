# Walkthrough - Profile Validation, Settings Cleanup, and Real-Time Messages

I have implemented:
1. **Resident Profile Update Form Validation**: Reusable `TextFormField` validators in `validators.dart` for Full Name (max 100 chars with live counter), Contact Number (`^09\d{9}$`), and Message box (max 200 chars with live counter), with Save button disabling and loading state.
2. **Admin System Settings Cleanup**: Removed **Blotter & Incident Rules** and **Resident Verification** sections/tabs from `SystemSettingsPage`, leaving a clean General Office Profile settings view.
3. **Real-Time Admin & Resident Messaging System**:
   - Real-time conversation list and chat views on both resident and staff/admin sides.
   - 200-character message limit with live counter ("150/200").
   - Atomic batch writes updating `lastMessage`, `lastMessageAt`, and unread counts (`unreadCountAdmin` & `unreadCountResident`).
   - Admin sidebar **Messages** navigation item with unread badge counter and search/filter by resident name.
   - Updated Firestore Security Rules enforcing 100-char name, 11-digit 09 phone, 200-char message limits, and `isActiveUser()` authorization.

---

## 🛠️ Changes Implemented

### 1. Reusable Validation & Profile Screen
- **`lib/validators.dart`**:
  - `validateFullName`: Required, trimmed, max 100 characters.
  - `validatePhone` / `validateUsernameMobile`: Digits only, exactly 11, starts with `09` (`^09\d{9}$`).
  - `validateMessage`: Max 200 characters, trimmed, non-blank.
- **`lib/resident/screens/profile_screen.dart`**:
  - Form wrapped with `_formKey` and `autovalidateMode`.
  - Full Name: `TextFormField` with `LengthLimitingTextInputFormatter(100)` and live counter.
  - Phone Number: `TextFormField` with `FilteringTextInputFormatter.digitsOnly`, `LengthLimitingTextInputFormatter(11)`, and `keyboardType: TextInputType.number`.
  - Save button disabled when form is invalid or saving + loading spinner while saving.

### 2. Admin System Settings Cleanup
- **`lib/staff/screens/system_settings_page.dart`**:
  - Removed **Blotter & Incident Rules** and **Resident Verification** tabs and navigation bar.
  - Streamlined screen into a clean General Office Profile view. All underlying Firestore documents remain intact.

### 3. Real-Time Messaging System & Sidebar Integration
- **`lib/staff/screens/admin_messages_page.dart`**:
  - Real-time stream of conversations from `/conversations` sorted by `lastMessageAt` descending.
  - Shows resident name, last message preview, timestamp, unread badge, and resident search box.
  - Conversation detail view: real-time message stream, 200-char input with live counter, auto-scroll, resets `unreadCountAdmin` on view, and sends staff replies via batch writes.
- **`lib/resident/screens/resident_chat_screen.dart`**:
  - Real-time message stream for the resident (`/conversations/{residentUid}/messages`).
  - 200-character input with live counter.
  - Sends messages via batch write updating `/conversations/{residentUid}` with `lastMessage`, `lastMessageAt`, and `unreadCountAdmin`.
- **`lib/staff/widgets/app_scaffold.dart` & `lib/staff/staff_main.dart`**:
  - Added **Messages** navigation item under `OPERATIONS` with unread badge counter.
- **`firestore.rules`**:
  - Added security rules for `/conversations/{conversationId}` and `/messages/{messageId}` enforcing `isActiveUser()`, `text.size() <= 200`, and `senderId == request.auth.uid`.
  - Updated user profile rules for name length <= 100 and phone `^09[0-9]{9}$`.

---

## 🧪 Verification & Test Results

### Automated Verification
- **`flutter analyze`**: **`No issues found!`** (0 errors, 0 warnings).
- **`flutter test`**: **`All tests passed!`** (7/7 unit and widget tests passed).

> [!NOTE]
> ### 📋 Test Instructions
> 1. **Profile Validation**: Edit profile in Resident App. Try a 101-character name, a non-09 number, or a 10-digit number. Confirm each is blocked with error messages and live counters.
> 2. **System Settings Cleanup**: Open admin System Settings. Confirm Blotter and Resident Verification tabs are removed and General Office Profile displays cleanly.
> 3. **Real-Time Messages**:
>    - Open Resident Chat and send a message (e.g. "Good morning Barangay Staff").
>    - Confirm the message appears on the Admin side in real time under the **Messages** sidebar item with an unread badge.
>    - Tap the conversation on Admin side, verify unread badge resets, and send a reply. Confirm the resident receives the reply in real time.
