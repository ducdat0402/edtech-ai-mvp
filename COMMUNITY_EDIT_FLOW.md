# 📚 Wiki-style Community Edit - Flow Hoạt Động

## 🎯 Tổng Quan

Tính năng cho phép người dùng đóng góp video và hình ảnh vào các bài học, tạo nội dung cộng đồng như Wikipedia.

---

## 🔄 Flow Hoạt Động Chi Tiết

### 1. **Hiển Thị Content Viewer Screen**

```
User mở bài học → ContentViewerScreen được load
```

**Frontend (`content_viewer_screen.dart`):**

```dart
@override
void initState() {
  super.initState();
  _loadContent();           // Load nội dung bài học
  _loadCommunityEdits();    // Load các đóng góp từ cộng đồng
}
```

**Quá trình:**
1. `_loadContent()`: Gọi API `GET /content/:id` để lấy thông tin bài học
2. `_loadCommunityEdits()`: Gọi API `GET /content-edits/content/:contentItemId` để lấy các edits đã được approve

---

### 2. **Hiển Thị Community Edits Section**

**UI Component (`_buildCommunityEditsSection`):**

```dart
Widget _buildCommunityEditsSection() {
  return Column(
    children: [
      // Header với button "Thêm"
      Row(
        children: [
          Text('Đóng góp từ cộng đồng'),
          TextButton.icon(
            onPressed: () => _showAddEditDialog(),  // Mở dialog để thêm edit
            icon: Icon(Icons.add),
            label: Text('Thêm'),
          ),
        ],
      ),
      
      // Hiển thị danh sách edits
      if (_isLoadingEdits)
        CircularProgressIndicator()
      else if (_communityEdits.isEmpty)
        Text('Chưa có đóng góp nào...')
      else
        ..._communityEdits.map((edit) => _buildEditCard(edit)),
    ],
  );
}
```

**Mỗi Edit Card hiển thị:**
- Avatar và tên người đóng góp
- Loại đóng góp (video/hình ảnh)
- Hình ảnh hoặc video player
- Chú thích (caption)
- Upvote/Downvote buttons
- Số lượng votes

---

### 3. **User Muốn Thêm Đóng Góp**

**Bước 1: Mở Dialog**

```dart
Future<void> _showAddEditDialog() async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => _AddEditDialog(),  // Dialog để chọn file
  );

  if (result != null && mounted) {
    await _submitEdit(result);  // Submit edit sau khi chọn file
  }
}
```

**Bước 2: Chọn File trong Dialog**

**UI (`_AddEditDialog`):**

```dart
class _AddEditDialogState extends State<_AddEditDialog> {
  String? _selectedType = 'add_image';  // Mặc định: thêm hình ảnh
  File? _selectedImage;
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();

  // Chọn hình ảnh từ gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _selectedType = 'add_image';
      });
    }
  }

  // Chọn video từ gallery
  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
        _selectedType = 'add_video';
      });
    }
  }
}
```

**User thao tác:**
1. Chọn loại đóng góp: "Thêm hình ảnh" hoặc "Thêm video"
2. Tap button "Chọn hình ảnh" hoặc "Chọn video"
3. Chọn file từ gallery
4. File được preview ngay trong dialog
5. Nhập chú thích (caption) và mô tả (description) - tùy chọn
6. Tap "Gửi" để submit

---

### 4. **Upload File Lên Server**

**Frontend (`_submitEdit`):**

```dart
Future<void> _submitEdit(Map<String, dynamic> data) async {
  try {
    final apiService = Provider.of<ApiService>(context, listen: false);
    String? imageUrl;
    String? videoUrl;

    // Bước 1: Upload file nếu có
    if (data['imageFile'] != null) {
      final uploadResult = await apiService.uploadImageForEdit(
        (data['imageFile'] as File).path,
      );
      imageUrl = uploadResult['imageUrl'];  // Nhận URL từ server
    }

    if (data['videoFile'] != null) {
      final uploadResult = await apiService.uploadVideoForEdit(
        (data['videoFile'] as File).path,
      );
      videoUrl = uploadResult['videoUrl'];  // Nhận URL từ server
    }

    // Bước 2: Submit edit với URL đã upload
    await apiService.submitContentEdit(
      contentItemId: widget.contentId,
      type: data['type'],           // 'add_image' hoặc 'add_video'
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      description: data['description'],
      caption: data['caption'],
    );

    // Bước 3: Reload danh sách edits
    _loadCommunityEdits();
  } catch (e) {
    // Show error message
  }
}
```

**API Call Flow:**

```
1. POST /content-edits/upload-image
   Body: multipart/form-data
   - image: File
   
   Response: {
     imageUrl: "/uploads/images/uuid.jpg",
     message: "Image uploaded successfully"
   }

2. POST /content-edits/content/:contentItemId/submit
   Body: {
     type: "add_image",
     imageUrl: "/uploads/images/uuid.jpg",
     description: "...",
     caption: "..."
   }
   
   Response: {
     id: "edit-uuid",
     status: "pending",
     ...
   }
```

---

### 5. **Backend Xử Lý Upload**

**Controller (`content-edits.controller.ts`):**

```typescript
@Post('upload-image')
@UseGuards(JwtAuthGuard)
@UseInterceptors(FileInterceptor('image'))
async uploadImage(@UploadedFile() file: Express.Multer.File) {
  // Gọi FileStorageService để lưu file
  const imageUrl = await this.fileStorageService.saveImage(file);
  return {
    imageUrl,
    message: 'Image uploaded successfully',
  };
}
```

**FileStorageService (`file-storage.service.ts`):**

```typescript
async saveImage(file: Express.Multer.File): Promise<string> {
  // 1. Validate file type và size
  const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
  if (!allowedMimeTypes.includes(file.mimetype)) {
    throw new BadRequestException('Invalid image type');
  }
  
  if (file.size > 10 * 1024 * 1024) {  // Max 10MB
    throw new BadRequestException('File too large');
  }

  // 2. Generate unique filename
  const fileExtension = path.extname(file.originalname);
  const filename = `${uuidv4()}${fileExtension}`;  // uuid.jpg
  
  // 3. Save file vào uploads/images/
  const filePath = path.join(this.imagesDir, filename);
  fs.writeFileSync(filePath, file.buffer);

  // 4. Return URL path
  return `/uploads/images/${filename}`;
}
```

**Kết quả:**
- File được lưu tại: `backend/uploads/images/uuid.jpg`
- URL để truy cập: `http://localhost:3000/uploads/images/uuid.jpg`
- File được serve static qua `main.ts`:

```typescript
app.useStaticAssets(join(process.cwd(), 'uploads'), {
  prefix: '/uploads',
});
```

---

### 6. **Backend Lưu Edit vào Database**

**Service (`content-edits.service.ts`):**

```typescript
async submitEdit(
  contentItemId: string,
  userId: string,
  type: ContentEditType,
  data: { videoUrl?: string; imageUrl?: string; ... }
): Promise<ContentEdit> {
  // 1. Verify content item exists
  const contentItem = await this.contentItemRepository.findOne({
    where: { id: contentItemId },
  });

  // 2. Validate based on type
  if (type === ContentEditType.ADD_VIDEO && !data.videoUrl) {
    throw new BadRequestException('Video URL is required');
  }

  // 3. Create ContentEdit entity
  const edit = this.contentEditRepository.create({
    contentItemId,
    userId,
    type,
    status: ContentEditStatus.PENDING,  // Mặc định: pending
    media: {
      videoUrl: data.videoUrl,
      imageUrl: data.imageUrl,
      caption: data.caption,
    },
    description: data.description,
  });

  // 4. Save to database
  return this.contentEditRepository.save(edit);
}
```

**Database Schema:**

```typescript
@Entity('content_edits')
export class ContentEdit {
  id: string;                    // UUID
  contentItemId: string;         // ID bài học
  userId: string;                // ID người đóng góp
  type: ContentEditType;         // 'add_video' | 'add_image' | ...
  status: ContentEditStatus;     // 'pending' | 'approved' | 'rejected'
  media: {
    videoUrl?: string;
    imageUrl?: string;
    caption?: string;
  };
  description: string;
  upvotes: number;                // Số upvote
  downvotes: number;              // Số downvote
  voters: string[];               // Danh sách user đã vote
  createdAt: Date;
  updatedAt: Date;
}
```

---

### 7. **Hiển Thị Edits Đã Approve**

**Frontend Load Edits:**

```dart
Future<void> _loadCommunityEdits() async {
  final apiService = Provider.of<ApiService>(context, listen: false);
  final edits = await apiService.getContentEdits(widget.contentId);
  // API: GET /content-edits/content/:contentItemId
  // Response chỉ trả về edits có status = 'approved'
  
  setState(() {
    _communityEdits = edits;
  });
}
```

**Backend (`content-edits.service.ts`):**

```typescript
async getEditsForContent(
  contentItemId: string,
  includePending: boolean = false,
): Promise<ContentEdit[]> {
  const where: any = { contentItemId };
  if (!includePending) {
    where.status = ContentEditStatus.APPROVED;  // Chỉ lấy approved
  }

  return this.contentEditRepository.find({
    where,
    relations: ['user'],  // Load thông tin user
    order: { createdAt: 'DESC' },  // Mới nhất trước
  });
}
```

---

### 8. **Hiển Thị Video/Image trong Edit Card**

**Video Player (`_VideoPlayerWidget`):**

```dart
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;  // "/uploads/videos/uuid.mp4"
  final bool isLocalFile;
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;

  Future<void> _initializeVideo() async {
    String url = widget.videoUrl;
    
    // Nếu là relative path, construct full URL
    if (!url.startsWith('http')) {
      url = 'http://26.213.113.234:3000$url';
    }
    
    // Initialize video player
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await _controller.initialize();
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video player
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        
        // Play/Pause button overlay
        GestureDetector(
          onTap: () {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          },
          child: Icon(
            _controller.value.isPlaying 
              ? Icons.pause_circle_outline 
              : Icons.play_circle_outline,
          ),
        ),
        
        // Progress bar
        VideoProgressIndicator(_controller),
      ],
    );
  }
}
```

**Image Display:**

```dart
if (media['imageUrl'] != null)
  ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      media['imageUrl'],  // Full URL hoặc relative path
      fit: BoxFit.cover,
      width: double.infinity,
      height: 200,
    ),
  ),
```

---

### 9. **Vote trên Edit**

**Frontend:**

```dart
Future<void> _voteOnEdit(String editId, bool isUpvote) async {
  final apiService = Provider.of<ApiService>(context, listen: false);
  await apiService.voteOnContentEdit(editId, isUpvote: isUpvote);
  // API: POST /content-edits/:id/vote
  // Body: { isUpvote: true/false }
  
  _loadCommunityEdits();  // Reload để update vote count
}
```

**Backend:**

```typescript
async voteOnEdit(id: string, userId: string, isUpvote: boolean) {
  const edit = await this.getEditById(id);
  
  // Check if user already voted
  if (edit.voters.includes(userId)) {
    throw new BadRequestException('User has already voted');
  }
  
  // Update vote count
  if (isUpvote) {
    edit.upvotes += 1;
  } else {
    edit.downvotes += 1;
  }
  
  edit.voters.push(userId);
  return this.contentEditRepository.save(edit);
}
```

---

### 10. **Approve Edit (Admin)**

**Backend (`approveEdit`):**

```typescript
async approveEdit(id: string): Promise<ContentEdit> {
  const edit = await this.getEditById(id);
  
  // Get content item
  const contentItem = await this.contentItemRepository.findOne({
    where: { id: edit.contentItemId },
  });
  
  // Apply edit to content item
  if (edit.type === ContentEditType.ADD_VIDEO && edit.media?.videoUrl) {
    contentItem.media = {
      ...(contentItem.media || {}),
      videoUrl: edit.media.videoUrl,  // Thêm video vào content item
    };
  } else if (edit.type === ContentEditType.ADD_IMAGE && edit.media?.imageUrl) {
    contentItem.media = {
      ...(contentItem.media || {}),
      imageUrl: edit.media.imageUrl,  // Thêm image vào content item
    };
  }
  
  // Save content item
  await this.contentItemRepository.save(contentItem);
  
  // Update edit status
  edit.status = ContentEditStatus.APPROVED;
  return this.contentEditRepository.save(edit);
}
```

**Kết quả:**
- Edit được approve → status = 'approved'
- Media được thêm vào ContentItem gốc
- Edit xuất hiện trong danh sách community edits

---

## 📊 Flow Diagram

```
┌─────────────────┐
│  User mở bài học │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────┐
│ Load Content + Edits    │
│ GET /content/:id        │
│ GET /content-edits/...  │
└────────┬─────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Hiển thị bài học +      │
│ Community Edits Section │
└────────┬─────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐  ┌──────────────┐
│ Xem    │  │ Thêm đóng góp│
│ Edits  │  │ (Tap "Thêm") │
└────────┘  └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │ Chọn File    │
            │ (Image/Video)│
            └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │ Upload File  │
            │ POST /upload │
            └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │ Submit Edit  │
            │ POST /submit │
            └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │ Status:      │
            │ PENDING      │
            └──────┬───────┘
                   │
         ┌─────────┴─────────┐
         │                   │
         ▼                   ▼
    ┌─────────┐         ┌─────────┐
    │ Approve │         │ Reject  │
    │ (Admin) │         │ (Admin) │
    └────┬────┘         └────┬────┘
         │                    │
         ▼                    ▼
    ┌─────────┐         ┌─────────┐
    │ APPROVED│         │REJECTED │
    │ Hiển thị│         │ Ẩn      │
    └─────────┘         └─────────┘
```

---

## 🔑 Key Points

1. **File Upload**: File được upload trước, sau đó submit edit với URL
2. **Status Flow**: `PENDING` → `APPROVED`/`REJECTED`
3. **Static Files**: Files được serve qua `/uploads` endpoint
4. **Video Player**: Tự động construct full URL từ relative path
5. **Voting**: Mỗi user chỉ vote 1 lần, tracked trong `voters` array
6. **Auto-Apply**: Khi approve, media tự động được thêm vào ContentItem gốc

---

## 🎯 Use Cases

### Use Case 1: User thêm hình ảnh minh họa
1. User đọc bài học về "Excel Formulas"
2. User có hình ảnh minh họa hay → Tap "Thêm"
3. Chọn hình ảnh từ gallery
4. Nhập chú thích: "Công thức SUM trong Excel"
5. Submit → Status: PENDING
6. Admin approve → Hình ảnh xuất hiện trong bài học

### Use Case 2: User thêm video tutorial
1. User học về "Python Functions"
2. User có video giải thích hay → Tap "Thêm"
3. Chọn video từ gallery
4. Nhập mô tả: "Video này giải thích cách dùng lambda functions"
5. Submit → Status: PENDING
6. Admin approve → Video xuất hiện, user khác có thể xem và vote

### Use Case 3: Community voting
1. User A thêm video
2. User B thấy hay → Upvote
3. User C thấy không hay → Downvote
4. Edit có 5 upvotes, 1 downvote
5. Edits có nhiều upvotes sẽ được ưu tiên hiển thị (có thể sort)

---

## 🚀 Next Steps (Có thể cải thiện)

1. **Auto-approve**: Nếu user có reputation cao, auto-approve
2. **Sort by votes**: Sắp xếp edits theo số upvotes
3. **Report abuse**: Cho phép report edits không phù hợp
4. **Edit history**: Lưu lịch sử chỉnh sửa
5. **Cloud storage**: Migrate từ local storage sang S3/Cloudinary

