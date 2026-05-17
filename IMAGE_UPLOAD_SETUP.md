# Image Upload Setup Guide (Free with ImgBB + Firestore)

## Overview
Shop owners can upload product/service images using **ImgBB** (free service), and the image URLs are stored in **Firestore**. Images display on the landing page marketplace.

---

## **Step 1: Get Your ImgBB API Key**

1. Go to **https://imgbb.com/**
2. Click **API** (top navigation)
3. Click **Get API key** button
4. Sign up with email (free account)
5. **Copy your API key** - looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

---

## **Step 2: Add Your API Key to the App**

Open `lib/services/image_upload_service.dart` (line 14):

```dart
// ⚠️ IMPORTANT: Replace with your ImgBB API key from https://imgbb.com/
static const String _imgbbApiKey = 'YOUR_IMGBB_API_KEY_HERE';
```

**Replace** `YOUR_IMGBB_API_KEY_HERE` with your actual API key:

```dart
static const String _imgbbApiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

---

## **Step 3: How It Works - Flow Diagram**

```
Shop Owner                    App                      ImgBB              Firestore
    |                          |                         |                    |
    |--Pick Image--->          |                         |                    |
    |                          |--Upload Image---------->|                    |
    |                          |                    (Free Service)             |
    |                          |<--Image URL-------(e.g., https://.....)      |
    |                          |--Save URL to Firestore------------------>    |
    |<--Show Success--          |                         |                    |
    |                          |                         |               URL stored
```

---

## **Step 4: Shop Owner Flow**

### **To Add/Upload a Product:**

1. **Shop Owner Screen** → Tap **"Add New Product"** button
2. Click **"Upload Product Imagery"** section
3. Tap **"Choose Files"** button
4. Select up to 5 images from phone gallery
5. Images will show preview thumbnails
6. Fill in product details (name, price, category, etc.)
7. Tap **"Publish"** button
   - Images automatically upload to ImgBB
   - Image URLs are saved to Firestore
   - Product goes live on marketplace

---

## **Step 5: Landing Page Display**

### **Marketplace Screen Shows:**
- Product images from Firestore URLs (cached for fast loading)
- Product name, shop owner, price, category
- Rating and reviews
- **Trending section**: Most booked products with images

### **Example File Locations:**
- **Shop Owner Add Screen**: `lib/shop_owner_screens/shop_owner_add_product_screen.dart`
- **Landing Page**: `lib/user_screens/landing_page_screen.dart`
- **Image Upload Service**: `lib/services/image_upload_service.dart`

---

## **Step 6: Testing**

1. **Configure your API key** (Step 2)
2. Run the app: `flutter run`
3. Sign in as shop owner
4. Go to **Shop Owner Screen** → **Products** tab
5. Tap **"Add New Product"**
6. Upload images and fill details
7. Tap **"Publish"**
8. Go to **Landing Page** → **Home** tab
9. Scroll to **"Market Showcase"** section
10. **You should see your product with images!**

---

## **Step 7: Firestore Structure**

When a product is published, it saves:

```json
{
  "products": {
    "product_id_123": {
      "productName": "Red Uniform",
      "price": 250.00,
      "category": "Uniform",
      "description": "High quality fabric",
      "imageUrls": [
        "https://i.ibb.co/ABC123/image1.jpg",
        "https://i.ibb.co/DEF456/image2.jpg"
      ],
      "shopOwnerId": "user_123",
      "createdAt": "2026-05-12T10:30:00Z"
    }
  }
}
```

---

## **Step 8: Free Tier Limits (ImgBB)**

✅ **Free Forever:**
- ✓ 32 MB per image upload
- ✓ Unlimited uploads
- ✓ Image hosting with URL
- ✓ No expiration date
- ✓ Fast CDN delivery

---

## **Step 9: Firestore Free Tier (Still Used)**

Your existing **Firestore** still stores:
- Product metadata (name, price, category, description)
- Image URLs (very small - just text)
- User data

**Firestore Free Tier:**
- 1 GB storage (plenty for URLs)
- 50k reads/day
- 20k writes/day

---

## **Troubleshooting**

### **Issue: "Upload failed"**
- ✓ Check your ImgBB API key is correct
- ✓ Make sure you've replaced `YOUR_IMGBB_API_KEY_HERE` with actual key
- ✓ Check internet connection

### **Issue: Image URL not saving to Firestore**
- ✓ Check Firestore security rules allow writes
- ✓ Verify user is authenticated

### **Issue: Images not showing on landing page**
- ✓ Make sure `imageUrls` array is saved to Firestore
- ✓ Check image URL format is valid (starts with `https://`)
- ✓ Wait a moment - images are cached, might take a few seconds

---

## **Key Files Modified**

- `lib/services/image_upload_service.dart` - Now uses ImgBB instead of Firebase Storage
- `pubspec.yaml` - Already has `dio` and `image_picker` packages

---

## **What You Don't Need Anymore**

❌ **Firebase Storage** (was costing money after free tier)
✅ **ImgBB** (free forever)
✅ **Firestore** (keeps using free tier for metadata + URLs only)

---

## **Summary**

| Step | Action | Where |
|------|--------|-------|
| 1 | Get ImgBB API key | imgbb.com |
| 2 | Add key to code | `image_upload_service.dart` line 14 |
| 3 | Shop owner uploads images | Shop Owner screen → Add Product |
| 4 | Images upload to ImgBB | Automatic when publishing |
| 5 | URLs saved to Firestore | Automatic |
| 6 | Display on landing page | Home → Market Showcase |

---

## **Next Steps**

1. Get your ImgBB API key from https://imgbb.com/
2. Update `image_upload_service.dart` with your key
3. Test by uploading a product
4. Images will appear on landing page!

**Questions?** Check the error messages in the app - they're descriptive!
