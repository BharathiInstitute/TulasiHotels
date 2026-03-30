# Firebase Project Migration Plan

## From: `login-radha` → To: `login1-aa21c`

**Project Name:** tulasi hotels  
**Project ID:** login1-aa21c

---

## Pre-Migration: Firebase Console Setup

Before touching any code, complete these steps in the [Firebase Console](https://console.firebase.google.com/project/login1-aa21c):

### Step 1 — Register Apps in New Project

| Platform | Bundle / Package ID | What You Get |
|----------|---------------------|--------------|
| **Android** | `in.liteapp.tulasihotels` | New `google-services.json` |
| **Android** (debug) | `com.example.tulasihotels` | Same `google-services.json` (add as 2nd app) |
| **iOS** | `com.example.tulasihotels` | New `GoogleService-Info.plist` (optional) |
| **Web** | (any label) | New web app config (apiKey, appId, etc.) |

> **How:** Firebase Console → Project Settings → General → "Add app" for each platform.

### Step 2 — Add SHA Certificates (Android)

Go to: Firebase Console → Project Settings → General → Android app (`in.liteapp.tulasihotels`) → SHA certificate fingerprints.

Add these SHA-1 hashes (from current `google-services.json`):
```
1d221b0b4fd9e53f1ca90d696fe25c42507468ee   (release keystore)
a20d57824c27f93ddfbdea658d5af80b822d10f0   (debug keystore)
```

> **Why:** Required for Google Sign-In and App Check on Android.

### Step 3 — Enable Firebase Services

Enable each service in the new project console:

| Service | Console Location | Notes |
|---------|-----------------|-------|
| **Authentication** | Build → Authentication → Sign-in method | Enable: Email/Password, Phone, Google |
| **Firestore** | Build → Firestore Database | Create database in `asia-south1` |
| **Storage** | Build → Storage | Create bucket in `asia-south1` |
| **Cloud Functions** | Build → Functions | Requires Blaze (pay-as-you-go) plan |
| **Cloud Messaging** | Engage → Messaging | Auto-enabled with project |
| **Remote Config** | Engage → Remote Config | Re-create all keys (see below) |
| **Analytics** | Analytics → Dashboard | Auto-enabled |
| **Crashlytics** | Release & Monitor → Crashlytics | Auto-enabled on first crash |
| **App Check** | Build → App Check | Register reCAPTCHA (web) + Play Integrity (Android) |

### Step 4 — Set Up Remote Config Keys

Re-create these keys in Firebase Console → Remote Config:

| Key | Type | Default Value |
|-----|------|---------------|
| `maintenance_mode` | Boolean | `false` |
| `min_app_version` | String | `1.0.0` |
| `force_update` | Boolean | `false` |
| `force_update_url` | String | _(empty)_ |
| `kill_switch_payments` | Boolean | `false` |
| `merchant_upi_id` | String | _(your UPI ID)_ |

### Step 5 — Set Cloud Functions Environment Variables

```bash
firebase use login1-aa21c

# Razorpay
firebase functions:config:set razorpay.key_id="YOUR_KEY"
firebase functions:config:set razorpay.key_secret="YOUR_SECRET"
firebase functions:config:set razorpay.webhook_secret="YOUR_WEBHOOK_SECRET"

# Brevo (Email OTP)
firebase functions:config:set brevo.smtp_user="YOUR_BREVO_USER"
firebase functions:config:set brevo.api_key="YOUR_BREVO_API_KEY"
firebase functions:config:set brevo.email="YOUR_SENDER_EMAIL"
```

### Step 6 — Enable Google Sign-In OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials?project=login1-aa21c)
2. Create OAuth 2.0 Client IDs for:
   - **Web application** — note the Client ID for `web/index.html`
   - **Android** — with SHA-1 fingerprints from Step 2
3. Add authorized JavaScript origins and redirect URIs

### Step 7 — Create Firestore Backup Bucket

```bash
gsutil mb -p login1-aa21c -l asia-south1 gs://login1-aa21c-firestore-backups
```

---

## Code Changes: File-by-File Checklist

After getting all new credentials from the Firebase Console, update these files:

---

### File 1: `.firebaserc`

**Location:** [.firebaserc](.firebaserc)  
**Change:** Project alias

```json
// OLD
{
  "projects": {
    "default": "login-radha"
  }
}

// NEW
{
  "projects": {
    "default": "login1-aa21c"
  }
}
```

---

### File 2: `lib/firebase_options.dart`

**Location:** [lib/firebase_options.dart](lib/firebase_options.dart)  
**Change:** ALL platform configs — apiKey, appId, messagingSenderId, projectId, storageBucket, authDomain, measurementId

> **Recommended:** Instead of manual editing, run:
> ```bash
> flutterfire configure --project=login1-aa21c
> ```
> This auto-generates the entire file with correct values.

**If editing manually**, replace every occurrence of:

| Old Value | New Value | Field |
|-----------|-----------|-------|
| `login-radha` | `login1-aa21c` | `projectId` |
| `login-radha.firebaseapp.com` | `login1-aa21c.firebaseapp.com` | `authDomain` |
| `login-radha.firebasestorage.app` | `login1-aa21c.firebasestorage.app` | `storageBucket` |
| `576503526807` | _(new project number)_ | `messagingSenderId` |
| `AIzaSyAA5Y-43RM2IItOsWpbygeHQhVbU2zFe48` | _(new web API key)_ | `apiKey` (web/windows) |
| `AIzaSyBqOxCE0Pzdkuwdb-cXOJ6qLBSzIAQVkqk` | _(new android API key)_ | `apiKey` (android) |
| `AIzaSyBWXVr6Y2Q73x9y6SueItUfie5H7r2NCAU` | _(new iOS API key)_ | `apiKey` (iOS) |
| `1:576503526807:web:23cf36d320396b512300d2` | _(new web appId)_ | `appId` (web/windows) |
| `1:576503526807:android:8b01290c6a28c6c32300d2` | _(new android appId)_ | `appId` (android) |
| `1:576503526807:ios:9ecf2c3027a9fe362300d2` | _(new iOS appId)_ | `appId` (iOS) |
| `G-WXNLFN8HEB` | _(new measurement ID)_ | `measurementId` (web) |

---

### File 3: `android/app/google-services.json`

**Location:** [android/app/google-services.json](android/app/google-services.json)  
**Change:** Entire file

> **Recommended:** Download fresh from Firebase Console:
> Firebase Console → Project Settings → General → Android app → Download `google-services.json`

> **Important:** After downloading, verify it contains entries for BOTH:
> - `com.example.tulasihotels` (debug)
> - `in.liteapp.tulasihotels` (production)
>
> If not, register both package names as separate Android apps in the console.

---

### File 4: `web/firebase-messaging-sw.js`

**Location:** [web/firebase-messaging-sw.js](web/firebase-messaging-sw.js)  
**Change:** Firebase config object

```javascript
// OLD
firebase.initializeApp({
    apiKey: "AIzaSyAA5Y-43RM2IItOsWpbygeHQhVbU2zFe48",
    authDomain: "login-radha.firebaseapp.com",
    projectId: "login-radha",
    storageBucket: "login-radha.firebasestorage.app",
    messagingSenderId: "576503526807",
    appId: "1:576503526807:web:23cf36d320396b512300d2",
});

// NEW — replace with values from Firebase Console → Web app config
firebase.initializeApp({
    apiKey: "NEW_WEB_API_KEY",
    authDomain: "login1-aa21c.firebaseapp.com",
    projectId: "login1-aa21c",
    storageBucket: "login1-aa21c.firebasestorage.app",
    messagingSenderId: "NEW_PROJECT_NUMBER",
    appId: "NEW_WEB_APP_ID",
});
```

---

### File 5: `web/desktop-login.html`

**Location:** [web/desktop-login.html](web/desktop-login.html) (around line 408)  
**Change:** `firebaseConfig` object

```javascript
// OLD
const firebaseConfig = {
    apiKey: "AIzaSyAA5Y-43RM2IItOsWpbygeHQhVbU2zFe48",
    authDomain: "login-radha.firebaseapp.com",
    projectId: "login-radha",
    storageBucket: "login-radha.firebasestorage.app",
    messagingSenderId: "576503526807",
    appId: "1:576503526807:web:23cf36d320396b512300d2"
};

// NEW
const firebaseConfig = {
    apiKey: "NEW_WEB_API_KEY",
    authDomain: "login1-aa21c.firebaseapp.com",
    projectId: "login1-aa21c",
    storageBucket: "login1-aa21c.firebasestorage.app",
    messagingSenderId: "NEW_PROJECT_NUMBER",
    appId: "NEW_WEB_APP_ID"
};
```

---

### File 6: `web/index.html`

**Location:** [web/index.html](web/index.html)  
**Change:** Google Sign-In Client ID meta tag

```html
<!-- OLD -->
<meta name="google-signin-client_id"
  content="576503526807-gjpgq9da62trcc0t09gediob7uina6g0.apps.googleusercontent.com">

<!-- NEW — get from Google Cloud Console → OAuth 2.0 Client IDs -->
<meta name="google-signin-client_id"
  content="NEW_OAUTH_CLIENT_ID.apps.googleusercontent.com">
```

---

### File 7: `firebase.json`

**Location:** [firebase.json](firebase.json)  
**Change:** `flutter.platforms` section — projectId and appId references

```json
// OLD
"flutter": {
    "platforms": {
        "android": {
            "default": {
                "projectId": "login-radha",
                "appId": "1:576503526807:android:8b01290c6a28c6c32300d2",
                "fileOutput": "android/app/google-services.json"
            }
        },
        "dart": {
            "lib/firebase_options.dart": {
                "projectId": "login-radha",
                "configurations": {
                    "android": "1:576503526807:android:8b01290c6a28c6c32300d2",
                    "ios": "1:576503526807:ios:9ecf2c3027a9fe362300d2",
                    "web": "1:576503526807:web:23cf36d320396b512300d2"
                }
            }
        }
    }
}

// NEW
"flutter": {
    "platforms": {
        "android": {
            "default": {
                "projectId": "login1-aa21c",
                "appId": "NEW_ANDROID_APP_ID",
                "fileOutput": "android/app/google-services.json"
            }
        },
        "dart": {
            "lib/firebase_options.dart": {
                "projectId": "login1-aa21c",
                "configurations": {
                    "android": "NEW_ANDROID_APP_ID",
                    "ios": "NEW_IOS_APP_ID",
                    "web": "NEW_WEB_APP_ID"
                }
            }
        }
    }
}
```

> **Note:** Running `flutterfire configure --project=login1-aa21c` updates this file automatically.

---

### File 8: `cors.json`

**Location:** [cors.json](cors.json)  
**Change:** Update hosting origins

```json
// OLD
"origin": ["https://tulasihotels.web.app", "https://tulasihotels.firebaseapp.com", "https://liteapp.in"]

// NEW — update firebaseapp.com domain; web.app depends on hosting site name
"origin": ["https://login1-aa21c.web.app", "https://login1-aa21c.firebaseapp.com", "https://liteapp.in"]
```

> **Note:** If you set up a custom Hosting site name (e.g., `tulasihotels`), the `.web.app` URL might stay the same. Verify in Firebase Console → Hosting → Domains.

After updating, apply to the new storage bucket:
```bash
gsutil cors set cors.json gs://login1-aa21c.firebasestorage.app
```

---

### File 9: `smart-deploy.ps1`

**Location:** [smart-deploy.ps1](smart-deploy.ps1)  
**Changes:** 11 occurrences of `login-radha`

| Line | Old | New |
|------|-----|-----|
| 124 | `$projectId = "login-radha"` | `$projectId = "login1-aa21c"` |
| 141 | `host=login-radha.web.app` | `host=login1-aa21c.web.app` |
| 154 | `host=login-radha.web.app` | `host=login1-aa21c.web.app` |
| 291 | `gs://login-radha.firebasestorage.app/downloads/windows/` | `gs://login1-aa21c.firebasestorage.app/downloads/windows/` |
| 322 | `gs://login-radha.firebasestorage.app/downloads/android/` | `gs://login1-aa21c.firebasestorage.app/downloads/android/` |
| 950 | `login-radha.firebasestorage.app` in download URL | `login1-aa21c.firebasestorage.app` |
| 986 | `gs://login-radha.firebasestorage.app/downloads/windows/` | `gs://login1-aa21c.firebasestorage.app/downloads/windows/` |
| 1064 | `login-radha.firebasestorage.app` in download URL | `login1-aa21c.firebasestorage.app` |
| 1096 | `gs://login-radha.firebasestorage.app/downloads/android/` | `gs://login1-aa21c.firebasestorage.app/downloads/android/` |
| 1226 | `https://login-radha.web.app/` | `https://login1-aa21c.web.app/` |
| 1227 | `https://login-radha.web.app/app/` | `https://login1-aa21c.web.app/app/` |

---

### File 10: `firestore.rules`

**Location:** [firestore.rules](firestore.rules)  
**Change:** Verify admin email reference. The hardcoded fallback admin `kehsaram001@gmail.com` is identity-based (not project-based), so it should still work. No project ID changes needed unless you want a different admin.

---

### File 11: `functions/src/__tests__/index.test.ts`

**Location:** [functions/src/__tests__/index.test.ts](functions/src/__tests__/index.test.ts)  
**Changes:**

| Line | Old | New |
|------|-----|-----|
| 503 | `const projectId = "login-radha";` | `const projectId = "login1-aa21c";` |
| 505 | `"gs://login-radha-firestore-backups"` | `"gs://login1-aa21c-firestore-backups"` |

---

### File 12: `functions/src/__tests__/emulator-verify.ts`

**Location:** [functions/src/__tests__/emulator-verify.ts](functions/src/__tests__/emulator-verify.ts)  
**Change:**

| Line | Old | New |
|------|-----|-----|
| 17 | `admin.initializeApp({ projectId: "login-radha" })` | `admin.initializeApp({ projectId: "login1-aa21c" })` |

---

### File 13: `functions/lib/__tests__/` (compiled JS)

**Location:** `functions/lib/__tests__/index.test.js` and `emulator-verify.js`  
**Action:** These are compiled from TypeScript. After updating the `.ts` source files, rebuild:

```bash
cd functions
npm run build
```

---

### File 14: `docs/environment-variables.md`

**Location:** [docs/environment-variables.md](docs/environment-variables.md) (line 65)  
**Change:**

```markdown
<!-- OLD -->
| Production | `login-radha` | Live users |

<!-- NEW -->
| Production | `login1-aa21c` | Live users |
```

---

### File 15: `docs/10K_SUBSCRIBER_AUDIT.md`

**Location:** [docs/10K_SUBSCRIBER_AUDIT.md](docs/10K_SUBSCRIBER_AUDIT.md) (line 970)  
**Change:**

```
OLD: gs://login-radha-firestore-backups
NEW: gs://login1-aa21c-firestore-backups
```

---

## Post-Migration: Deploy & Verify Checklist

### Deploy Security Rules & Indexes

```bash
firebase use login1-aa21c
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

### Deploy Cloud Functions

```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

### Deploy Web Hosting

```bash
flutter build web --release
# Copy build/web to dist/ (per hosting config)
firebase deploy --only hosting
```

### Apply CORS Config

```bash
gsutil cors set cors.json gs://login1-aa21c.firebasestorage.app
```

### Verification Tests

| # | Test | How |
|---|------|-----|
| 1 | **Web app loads** | Visit `https://login1-aa21c.web.app` |
| 2 | **Email/Password login** | Create test account, log in |
| 3 | **Google Sign-In** | Test on web and Android |
| 4 | **Phone OTP** | Send OTP, verify |
| 5 | **Firestore read/write** | Create a bill, verify it appears |
| 6 | **Storage upload** | Upload a shop logo |
| 7 | **Cloud Functions** | Test payment link creation |
| 8 | **FCM push notification** | Send test notification from console |
| 9 | **Remote Config** | Toggle maintenance_mode, verify app responds |
| 10 | **Crashlytics** | Force a crash, check console |
| 11 | **Desktop login link** | Test browser → Windows app linking |
| 12 | **Offline mode** | Turn off WiFi, create a bill, reconnect, verify sync |
| 13 | **App Check** | Verify unverified requests are blocked |

---

## Quick Command: Full Migration

After getting all new credentials from Firebase Console, the fastest path is:

```bash
# 1. Switch Firebase CLI to new project
firebase use login1-aa21c

# 2. Auto-generate firebase_options.dart + google-services.json
flutterfire configure --project=login1-aa21c

# 3. Manually update the remaining files (web/, smart-deploy.ps1, cors.json, etc.)

# 4. Deploy everything
firebase deploy --only firestore:rules,firestore:indexes,storage,functions,hosting

# 5. Apply CORS
gsutil cors set cors.json gs://login1-aa21c.firebasestorage.app
```

---

## Data Migration (If Needed)

If you need to copy existing data from `login-radha` to `login1-aa21c`:

```bash
# Export from old project
gcloud firestore export gs://login-radha-firestore-backups/migration --project=login-radha

# Import into new project
gcloud firestore import gs://login-radha-firestore-backups/migration --project=login1-aa21c
```

> **Note:** Storage files (images, downloads) must be copied separately:
> ```bash
> gsutil -m cp -r gs://login-radha.firebasestorage.app/ gs://login1-aa21c.firebasestorage.app/
> ```

---

## Summary: All Files That Need Changes

| # | File | Type of Change |
|---|------|----------------|
| 1 | `.firebaserc` | Project ID |
| 2 | `lib/firebase_options.dart` | All credentials (use `flutterfire configure`) |
| 3 | `android/app/google-services.json` | All credentials (download from console) |
| 4 | `web/firebase-messaging-sw.js` | Web Firebase config |
| 5 | `web/desktop-login.html` | Web Firebase config |
| 6 | `web/index.html` | Google Sign-In OAuth Client ID |
| 7 | `firebase.json` | Flutter platform projectId + appIds |
| 8 | `cors.json` | Hosting domain origins |
| 9 | `smart-deploy.ps1` | 11 references to old project/bucket |
| 10 | `firestore.rules` | No change needed (identity-based, not project-based) |
| 11 | `storage.rules` | No change needed |
| 12 | `firestore.indexes.json` | No change needed (deploy to new project) |
| 13 | `functions/src/__tests__/index.test.ts` | Test project ID + backup bucket |
| 14 | `functions/src/__tests__/emulator-verify.ts` | Test project ID |
| 15 | `functions/lib/__tests__/*.js` | Rebuild from TypeScript |
| 16 | `docs/environment-variables.md` | Project ID reference |
| 17 | `docs/10K_SUBSCRIBER_AUDIT.md` | Backup bucket reference |

**Total: 15 files to edit + 2 compiled files to rebuild**
