# LiveDB 🚀

**The Easiest Cloud Database & Storage for Flutter.**

LiveDB provides a complete backend solution with **Database** and **Cloud Storage** capabilities. It's designed to be simple, fast, and secure.

[![Live DBs Official Website](livedbs.web.app)](livedbs.web.app/)



<a href="livedbs.web.app" target="_blank">
<img src="screenshots/1.png">
</a>

## 🔥 Features

- 🗄️ **NoSQL Database** - Easy document storage (Projects > Collections > Documents).
- 📁 **Cloud Storage** - Upload images, videos, and files with ease.
- 🔒 **Encryption** - Optional secure storage for sensitive files.
- 🚀 **Chunked Uploads** - Handle huge files (1GB+) reliably.
- 🚀 **Different-Types Of Uploading** - File, Base64 (Bytes), and Chunked support.
- 📱 **Cross-Platform** - Works on iOS, Android, Web, and Desktop.
- ⛈️ **Local-Storage** - Offline DataBase Features.

---

## 🛠️ Installation

Add `livedb` to your `pubspec.yaml`:

```yaml
dependencies:
  livedb: ^1.0.1
```

---

<a href="livedbs.web.app/api-docs" target="_blank"> API Documentaion </a>
<a href="livedbs.web.app/" target="_blank"> Login For (Token) APi Key  </a>

---

## 🚀 Quick Start

### 1. Initialize

```dart
import 'package:livedb/livedb.dart';

void main() {
  // Initialize
  // Note: Generate a token using email the first time
  LiveDB().generateAndSetToken('user@example.com');
  
  runApp(MyApp());
}
```

### 2. Configuration (Offline Support)

Enable **Local Storage** to cache data and load it automatically when the device is offline.

```dart
// Custom Configuration
final config = LiveDBConfig(
  enableLocalStorage: true, // 💾 Enable offline caching (Default: false)
  enableLogging: true,      // 🐛 Enable debug logs
);

// Initialize with config
final liveDb = LiveDB(config);

// Set Token Directly (if already known)
liveDb.setToken('YOUR_EXISTING_TOKEN');
```

---

# 🗄️ Database Examples

**Add Data:**
```dart
// Create a reference to your collection
final users = LiveDB().db.collection('my_app', 'users');

// Add a new user
await users.add({
  'name': 'John Doe',
  'age': 25,
  'role': 'developer',
});
```

**Get Data (Query):**
```dart
// Fetch users where age > 18
// If offline, this will load from local storage if enabled!
final result = await users.get(filters: {
  'age[gt]': 18,
  '_sort': 'created_at:desc'
});

print(result['data']);
```

---

# 📁 Storage Examples

**1. Smart Upload (Recommended):**
Automatically chooses between direct or chunked upload based on file size (Default threshold > 5MB uses chunks).
```dart
import 'dart:io';

final result = await LiveDB().upload(
  File('path/to/image.jpg'), 
  folderName: 'avatars',
  onProgress: (percent, sent, total) => print('Upload: ${(percent * 100).toInt()}%')
);

print('File Link: ${result.link}');
```

**2. Upload File (Direct):**
Best for small files (< 5MB).
```dart
final result = await LiveDB().uploadFile(
  File('path/to/small_image.jpg'), 
  folderName: 'avatars'
);
```

**3. Upload by Chunks (Large Files):**
Best for large videos or datasets (100MB, 1GB+).
```dart
final result = await LiveDB().uploadFileByChunks(
  File('path/to/video.mp4'),
  // Optional: Custom chunk size (default 512KB)
  chunkSize: 1024 * 1024, 
);
```

**4. Upload Base64 (Bytes):**
Upload directly from memory (Uint8List).
```dart
final result = await LiveDB().uploadByBase64(
  myBytes, // Uint8List
  fileName: 'image.png',
);
```

**5. Upload Base64 by Chunks:**
Upload large memory buffers in chunks.
```dart
final result = await LiveDB().uploadByBase64Chunks(
  largeBytes, // Uint8List
  fileName: 'video.mp4',
);
```

**Delete File:**
```dart
await LiveDB().deleteFile('https://link..../file_link');
```

---

## 🧩 Advanced Usage

### Fluent API
LiveDB uses a fluent API for database operations, similar to other popular NoSQL libraries.

```dart
final db = LiveDB().db;

// Project Level
await db.project('new_app').create(description: 'My App DB');

// Collection Level
final posts = db.project('social_app').collection('posts');
await posts.add({'title': 'Hello World'});

// Document Level
final doc = posts.doc('post_1');
await doc.get();
await doc.update({'title': 'Updated'});
```

### Secured Storage
Upload sensitive files with encryption enabled.

```dart
await LiveDB().uploadFile(
  File('secret.pdf'),
  isSecret: true // Only accessible with your token
);
```

[![Live DBs Storage Demo](https://github.com/HassanAmeer/livedb_flutter_package/blob/main/screenshots/1.png)](https://github.com/HassanAmeer/livedb_flutter_package/blob/main/screenshots/1.png)
---

## ❤️ Support
If you like **LiveDB**, please give it a star on [GitHub](https://github.com/HassanAmeer/livedb_flutter_package)! 
Issues or questions? [File an issue](https://github.com/HassanAmeer/livedb_flutter_package/issues).
