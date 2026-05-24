# How to Publish Activity Tracker on Google Play Store
### Complete Step-by-Step Guide

---

## ✅ What You Have Ready

| Item | Location |
|------|----------|
| Signed AAB (release build) | `build/app/outputs/bundle/release/app-release.aab` |
| App Icon (512×512) | `assets/icons/playstore_icon_512.png` |
| Feature Graphic (1024×500) | `assets/icons/feature_graphic_1024x500.png` |
| Screenshots (5) | `assets/screenshots/` folder |
| Privacy Policy URL | https://pvijaysimhareddy.github.io/ActivityTrackerFlutter/privacy-policy.html |
| Store listing text | `store_listing.md` |

---

## PART 1 — Open Play Console

1. Open your browser and go to:
   👉 **https://play.google.com/console**

2. Sign in with the Google account linked to your Play Developer account.

3. Click the blue **"Create app"** button in the top-right corner.

---

## PART 2 — Create the App

Fill in the form that appears:

| Field | Value |
|-------|-------|
| App name | `Activity Tracker – Fitness & Life Goals` |
| Default language | `English (United States)` |
| App or game | `App` |
| Free or paid | `Free` |

- Tick both **"I acknowledge this app meets the Developer Programme Policies"** checkboxes
- Click **"Create app"**

---

## PART 3 — Dashboard Overview

After creating the app, you'll land on the app dashboard.
On the **left sidebar** you'll see a list of sections to complete.
Each section has a ✅ when done. You need to complete all of them before publishing.

---

## PART 4 — Store Listing

**Left sidebar → "Grow" → "Store presence" → "Main store listing"**

### 4a — App Details
| Field | Value |
|-------|-------|
| App name | `Activity Tracker – Fitness & Life Goals` |
| Short description | `Track workouts, diet, habits & goals with your personal AI fitness coach.` |
| Full description | *(copy the full description block from `store_listing.md`)* |

### 4b — Graphics

**App icon**
- Click "App icon" → Upload → select `assets/icons/playstore_icon_512.png`

**Feature graphic**
- Click "Feature graphic" → Upload → select `assets/icons/feature_graphic_1024x500.png`

**Phone screenshots** (minimum 2 required)
- Click "Add phone screenshots"
- Upload all 5 files from `assets/screenshots/`:
  - `dashboard.png`
  - `training.png`
  - `diet.png`
  - `habits.png`
  - `goals.png`

### 4c — Categorisation
| Field | Value |
|-------|-------|
| App category | `Health & Fitness` |
| Tags | `fitness tracker`, `workout log`, `habit tracker`, `calorie counter`, `goal setting` |

### 4d — Contact Details
| Field | Value |
|-------|-------|
| Email address | `buntypeddi0@gmail.com` |
| Website (optional) | `https://pvijaysimhareddy.github.io/ActivityTrackerFlutter/` |

Click **"Save"** at the bottom.

---

## PART 5 — App Content

**Left sidebar → "Policy" → "App content"**

Work through each section:

### 5a — Privacy Policy
- Click **"Start"** next to Privacy policy
- Paste this URL: `https://pvijaysimhareddy.github.io/ActivityTrackerFlutter/privacy-policy.html`
- Click **"Save"**

### 5b — Ads
- Click **"Start"** next to Ads
- Select **"No, my app does not contain ads"**
- Click **"Save"**

### 5c — App Access
- Click **"Start"** next to App access
- Select **"All or most functionality is accessible without special access"**
- Click **"Save"**

### 5d — Content Rating
- Click **"Start"** next to Content ratings
- Click **"Start questionnaire"**
- Enter your email address
- Select category: **"Utility"**
- Answer all questions:
  - Violence: **No**
  - Sexual content: **No**
  - Profanity: **No**
  - Controlled substances: **No**
  - Miscellaneous: **No** to everything
- Click **"Save questionnaire"** → **"Calculate rating"** → **"Apply rating"**

### 5e — Target Audience
- Click **"Start"** next to Target audience and content
- Select age group: **"18 and over"**
- Appeal to children: **"No"**
- Click **"Save"** → **"Next"** → **"Save"**

### 5f — Data Safety
- Click **"Start"** next to Data safety
- **Does your app collect or share any of the required user data types?** → **"Yes"**
- Tick the following:
  - ✅ **Personal info** → Name, Email address
  - ✅ **App activity** → App interactions
- For each selected type, mark:
  - Collected: **Yes**
  - Shared with third parties: **No**
  - Required or optional: **Optional** (users can use as guest)
  - Purpose: **App functionality**
- Click **"Save"** → **"Submit"**

### 5g — Government Apps
- Click **"Start"** next to Government apps
- Select **"None of the above apply to my app"**
- Click **"Save"**

### 5h — Financial Features (if prompted)
- Select **"None of the above"**
- Click **"Save"**

---

## PART 6 — Upload the AAB (Release Build)

**Left sidebar → "Testing" → "Internal testing"**

1. Click **"Create new release"**

2. Under "App bundles", click **"Upload"**
   - Navigate to and select: `build/app/outputs/bundle/release/app-release.aab`
   - Wait for upload to complete (57 MB — may take a minute)

3. Fill in release details:
   | Field | Value |
   |-------|-------|
   | Release name | `1.0.0` |
   | Release notes | `Initial release of Activity Tracker.` |

4. Click **"Save"** → **"Review release"** → **"Start rollout to Internal testing"**

---

## PART 7 — Test on Internal Track (Optional but Recommended)

1. **Left sidebar → "Testing" → "Internal testing" → "Testers" tab**
2. Click **"Create email list"** → add your own email → save
3. Copy the **opt-in URL** shown and open it on your phone
4. Install the app and test it works correctly from the Play Store

---

## PART 8 — Submit to Production

Once you're happy with internal testing:

1. **Left sidebar → "Release" → "Production"**
2. Click **"Create new release"**
3. Click **"Promote from Internal testing"** → select the `1.0.0` release
4. Release notes: `Initial release of Activity Tracker.`
5. Click **"Save"** → **"Review release"**
6. Check that all sections show ✅ (no errors)
7. Set **"Rollout percentage"** to `100%`
8. Click **"Send for review"**

---

## PART 9 — Wait for Google Review

- Google will review your app. This takes **1–3 business days** for first submissions.
- You'll receive an email at `buntypeddi0@gmail.com` when approved or if changes are needed.
- Once approved, the app goes live on the Play Store automatically.
- Search for it at: **https://play.google.com/store** using "Activity Tracker Viral Systems"

---

## ⚠️ Common Rejection Reasons & How to Avoid Them

| Issue | Prevention |
|-------|-----------|
| Missing privacy policy | ✅ Already hosted and linked |
| Low-quality screenshots | ✅ Real device screenshots uploaded |
| App crashes on launch | ✅ Tested on emulator — working |
| Misleading description | ✅ Description matches actual features |
| No content rating | ✅ Complete section 5d above |
| Data safety incomplete | ✅ Complete section 5f above |

---

## 🔄 How to Publish Future Updates

When you make changes to the app:

1. Bump the version in `android/app/build.gradle.kts`:
   ```kotlin
   versionCode = 2          // increment by 1 each release
   versionName = "1.1.0"   // update version name
   ```

2. Rebuild the AAB:
   ```bash
   cd /home/boss/ActivityTrackerFlutter
   ANDROID_HOME=/home/boss/android-sdk ./android/gradlew bundleRelease -p android
   ```

3. Go to Play Console → **Production** → **Create new release** → upload new AAB → submit.

---

*Good luck with the launch! 🚀*
