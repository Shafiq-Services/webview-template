# 🐛 Debug Testing Guide for IAP Implementation

## 🚀 How to Test and Debug

### **Step 1: Build and Install Debug Version**
```bash
flutter build apk --debug
# Install the debug APK on your device
```

### **Step 2: Connect Debug Console**
```bash
flutter logs
# OR use Android Studio logcat
# OR connect via USB debugging and use:
adb logcat | grep "IAP\|DishUP"
```

### **Step 3: Navigate to Pricing Page**
1. Open your app
2. Navigate to the pricing page (URL containing `/Pricing` or `/pricing`)
3. Watch the console for debug messages

## 🔍 Debug Messages to Look For

### **App Initialization:**
```
🚀 Subscription Controller: Initializing...
🏪 IAP Service: Starting initialization...
🏪 IAP Service: Store available: true/false
✅ IAP Service: Service initialized successfully
```

### **Page Detection:**
```
🔍 IAP: Checking if should inject JavaScript...
🔍 IAP: Current URL: https://dishup.uk/Pricing
🔍 IAP: Is pricing page: true
💉 IAP: Injecting JavaScript into pricing page
```

### **JavaScript Injection:**
```
💉 IAP: JavaScript code length: XXXX characters
💉 IAP: Executing JavaScript...
✅ IAP: JavaScript injection completed successfully
```

### **WebView Console (JavaScript Side):**
```
🔍 DishUP IAP: Looking for pricing buttons...
🔍 DishUP IAP: Found X buttons on page
🔍 DishUP IAP: Button 0 details:
  - Text: Start 7-Day Free Trial
  - Parent card exists: true
✅ DishUP IAP: Found monthly subscription button 1
🔧 DishUP IAP: Adding click listener to monthly button
```

### **Button Click:**
```
🎯 DishUP IAP: Monthly button clicked!
🚀 DishUP IAP: window.flutter_inappwebview exists: true
🚀 DishUP IAP: Calling purchaseMonthlySubscription handler
🎯 IAP: Monthly subscription purchase requested from WebView
💰 Subscription Controller: Monthly purchase requested
💳 IAP Service: Purchase requested for product: monthly_premium
```

## ❌ Troubleshooting Common Issues

### **Issue 1: No JavaScript Injection**
**Symptoms:** No `💉` messages in console
**Check:**
- Is the URL correct? Look for `🔍 IAP: Current URL:`
- Is page detection working? Look for `🔍 IAP: Is pricing page:`

### **Issue 2: Buttons Not Found**
**Symptoms:** `🔍 DishUP IAP: Found 0 buttons` or no button details
**Check:**
- Wait longer for page to load
- Check if page structure matches expected HTML

### **Issue 3: Flutter Bridge Not Available**
**Symptoms:** `🚀 DishUP IAP: window.flutter_inappwebview exists: false`
**Check:**
- JavaScript handlers were set up properly
- WebView settings allow JavaScript

### **Issue 4: No IAP Products Found**
**Symptoms:** `💳 IAP Service: Available products: []`
**Check:**
- Google Play Console product IDs are correct
- App is signed with release key for testing
- Google Play licensing is working

### **Issue 5: Store Not Available**
**Symptoms:** `🏪 IAP Service: Store available: false`
**Check:**
- Device has Google Play Store
- Google Play Services are updated
- Test on real device (not emulator)

## 🧪 Test Cases to Verify

### ✅ **Successful Flow:**
1. App initializes IAP service
2. Page detects pricing URL
3. JavaScript injects successfully  
4. Buttons are found and modified
5. Button click triggers Flutter handler
6. Native purchase dialog appears

### ❌ **Expected Failures (for debugging):**
1. **Emulator Testing:** Store not available
2. **Wrong Product IDs:** Products not found
3. **Network Issues:** Product loading fails
4. **Wrong Page:** JavaScript not injected

## 📱 Real Device vs Emulator

**Use Real Device For:**
- Testing actual IAP functionality
- Google Play Store integration
- Purchase flows

**Emulator Can Be Used For:**
- JavaScript injection testing
- Button detection
- UI flow verification

## 🔧 Debug Controls

**Enable All Debug Logs:**
- All messages use `if (kDebugMode)` so they only show in debug builds

**Console Filtering:**
- Search for "IAP" or "DishUP" in logs
- Look for emoji prefixes: 🚀 🔍 💉 🎯 💰 💳 ✅ ❌

**Key Checkpoints:**
1. **Initialization:** 🚀 messages
2. **Page Detection:** 🔍 messages  
3. **Injection:** 💉 messages
4. **Button Discovery:** 🔧 messages
5. **Clicks:** 🎯 messages
6. **Purchases:** 💰 💳 messages

## 📞 What to Share for Help

If something isn't working, share:
1. **Full console output** from app launch to button click
2. **Current URL** when on pricing page
3. **Device type** (real device vs emulator)
4. **Google Play Console** product setup screenshots

The comprehensive debug logging will help identify exactly where the process is failing! 🚀


