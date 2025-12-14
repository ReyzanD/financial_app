# 🔍 Map Search - Testing & Debugging Guide

## ✅ What Was Fixed

### **Critical Fix: User-Agent Header**
The Nominatim API **requires** a User-Agent header. Without it, requests are blocked!

**Before:**
```dart
final response = await http.get(url);
// ❌ FAILS - No User-Agent
```

**After:**
```dart
final response = await http.get(
  url,
  headers: {
    'User-Agent': 'FinancialApp/1.0 (financial.app.makassar)',
    'Accept': 'application/json',
  },
);
// ✅ WORKS - Has User-Agent
```

### **Other Improvements:**
1. ✅ Added **debug logging** (check console)
2. ✅ Added **country filter** (countrycodes=id for Indonesia)
3. ✅ Improved **error messages**
4. ✅ Added **quick search buttons** for popular places
5. ✅ Better **search query** formatting
6. ✅ Increased **result limit** to 5

---

## 🧪 How to Test

### **Step 1: Open Map**
1. Go to **Add Transaction** screen
2. Click **"Pilih dari Peta"** (green button)
3. Map should open with search bar

### **Step 2: Try Quick Search Buttons**
Click these buttons that appear below search bar:
- ✅ **Pantai Losari**
- ✅ **Trans Studio**
- ✅ **Fort Rotterdam**
- ✅ **Mall Panakkukang**

**Expected Result:**
- Loading spinner appears
- Map moves to location
- Red marker appears
- Green success message shows
- Location card appears at bottom

### **Step 3: Try Manual Search**
Type in search bar and press Enter:

**Test These:**
```
✅ "Pantai Losari"
✅ "Trans Studio Makassar"
✅ "Losari Beach"
✅ "Mall GTC"
✅ "Universitas Hasanuddin"
✅ "Pelabuhan Makassar"
```

### **Step 4: Check Console Logs**

Open your IDE's **Debug Console** and look for:

**Successful Search:**
```
🔍 Searching for: Pantai Losari, Makassar, Sulawesi Selatan, Indonesia
📡 API URL: https://nominatim.openstreetmap.org/search?...
📥 Response status: 200
📥 Response body: [{"lat":"-5.1363","lon":"119.4067",...}]
✅ Found location: Pantai Losari, Makassar at (-5.1363, 119.4067)
```

**Failed Search:**
```
🔍 Searching for: NonExistentPlace, Makassar, Sulawesi Selatan, Indonesia
📡 API URL: https://nominatim.openstreetmap.org/search?...
📥 Response status: 200
📥 Response body: []
❌ No results found
```

---

## 🐛 Troubleshooting

### **Problem: "Lokasi tidak ditemukan"**

**Possible Causes:**
1. **Typo in search** - Try simpler names
2. **Place doesn't exist** - Try popular landmarks
3. **Too specific** - Try broader search

**Solutions:**
- Use quick search buttons first
- Try: "Pantai Losari" instead of "Pantai Losari Beach"
- Check spelling

### **Problem: "Gagal mencari lokasi"**

**Possible Causes:**
1. **No internet connection**
2. **API timeout**
3. **API blocked your IP** (rare)

**Solutions:**
- Check internet connection
- Wait 1-2 seconds between searches
- Try again later

**Check Console for:**
```
❌ Search error: SocketException: Failed host lookup
// = No internet

❌ HTTP Error: 403
// = API blocked (too many requests)

❌ HTTP Error: 500
// = API server error (temporary)
```

### **Problem: Red marker doesn't appear**

**Possible Causes:**
1. Map not loaded yet
2. Location outside visible area
3. Marker rendering issue

**Solutions:**
- Wait for map to fully load
- Zoom out using **-** button
- Try tapping map directly

---

## 📊 Expected Behavior

### **When Search Succeeds:**
1. ⏳ Loading spinner appears (1-2 seconds)
2. 🗺️ Map **smoothly moves** to location
3. 📍 **Red marker** appears at exact spot
4. ✅ **Green snackbar** shows: "✓ Ditemukan: [Place Name]"
5. 📋 **Bottom card** shows coordinates

### **When Search Fails:**
1. ⏳ Loading spinner appears
2. 🟠 **Orange snackbar** shows: "Lokasi 'X' tidak ditemukan"
3. Map stays at current position
4. No marker added

### **When Network Error:**
1. ⏳ Loading spinner appears
2. 🔴 **Red snackbar** shows: "Gagal mencari: [Error]"
3. Console shows detailed error

---

## 🎯 Testing Checklist

Mark these as you test:

**Basic Functionality:**
- [ ] Map opens when clicking "Pilih dari Peta"
- [ ] Search bar is visible and functional
- [ ] Can type in search bar
- [ ] Loading spinner appears when searching
- [ ] Can press Enter to search
- [ ] Can click search icon to search

**Quick Search:**
- [ ] "Pantai Losari" button works
- [ ] "Trans Studio" button works
- [ ] "Fort Rotterdam" button works
- [ ] "Mall Panakkukang" button works

**Search Results:**
- [ ] Successful search shows green message
- [ ] Failed search shows orange message
- [ ] Red marker appears on success
- [ ] Map moves to correct location
- [ ] Bottom card shows lat/lng

**Manual Searches:**
- [ ] Search: "Pantai Losari" ✅
- [ ] Search: "Trans Studio" ✅
- [ ] Search: "Mall GTC" ✅
- [ ] Search: "InvalidPlaceName" ❌ (should fail gracefully)

**Error Handling:**
- [ ] Empty search shows warning
- [ ] No internet shows error
- [ ] Invalid response handled gracefully

**Console Logs:**
- [ ] Shows "🔍 Searching for: ..."
- [ ] Shows "📡 API URL: ..."
- [ ] Shows "📥 Response status: 200"
- [ ] Shows "✅ Found location: ..." on success
- [ ] Shows "❌ No results found" on failure

---

## 📝 Example Searches

### **Should Work:**
| Search Term | Expected Result |
|-------------|----------------|
| Pantai Losari | Waterfront area |
| Trans Studio Makassar | Shopping mall |
| Fort Rotterdam | Historical fort |
| Mall Panakkukang | Shopping center |
| Losari Beach | Waterfront (English) |
| GTC Mall | Shopping center |
| Unhas | University |

### **Might Not Work:**
| Search Term | Why |
|-------------|-----|
| MyHouse123 | Too specific |
| Random Street | Not in database |
| Typo Placce | Spelling error |
| 🏖️ (emoji) | Special characters |

---

## 🔍 Debug Console Examples

### **Success Case:**
```
🔍 Searching for: Pantai Losari, Makassar, Sulawesi Selatan, Indonesia
📡 API URL: https://nominatim.openstreetmap.org/search?q=Pantai%20Losari%2C%20Makassar%2C%20Sulawesi%20Selatan%2C%20Indonesia&format=json&limit=5&countrycodes=id
📥 Response status: 200
📥 Response body: [{"place_id":12345,"lat":"-5.1363","lon":"119.4067","display_name":"Pantai Losari, Makassar, Sulawesi Selatan, Indonesia",...}]
✅ Found location: Pantai Losari, Makassar, Sulawesi Selatan, Indonesia at (-5.1363, 119.4067)
```

### **Not Found Case:**
```
🔍 Searching for: RandomPlace, Makassar, Sulawesi Selatan, Indonesia
📡 API URL: https://nominatim.openstreetmap.org/search?q=RandomPlace...
📥 Response status: 200
📥 Response body: []
❌ No results found
```

### **Network Error:**
```
🔍 Searching for: Pantai Losari, Makassar, Sulawesi Selatan, Indonesia
❌ Search error: SocketException: Failed host lookup: 'nominatim.openstreetmap.org'
Stack trace: ...
```

---

## ✅ If Everything Works:

You should see:
1. ✅ Quick search buttons work instantly
2. ✅ Manual search finds locations
3. ✅ Map moves smoothly to results
4. ✅ Red markers appear correctly
5. ✅ Success messages show
6. ✅ Console logs show API responses
7. ✅ Can select location and return to form

---

## 🚀 Next Steps After Testing:

If search works:
- ✅ Test with 5-10 different locations
- ✅ Try both quick buttons and manual search
- ✅ Verify coordinates are correct
- ✅ Confirm location saves to transaction

If search fails:
- 📋 Copy console logs
- 🔍 Check error messages
- 🌐 Verify internet connection
- 📱 Try on different device/emulator

---

**The search should now work!** The User-Agent header was the key missing piece. 🎉
