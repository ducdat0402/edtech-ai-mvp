# 🔧 Error Handling Guide

## ✅ Đã cải thiện

### 1. Auth Service Error Handling

**Trước:**
- Chỉ hiển thị raw error message
- Không parse DioException
- Không extract message từ backend response

**Sau:**
- ✅ Parse DioException đúng cách
- ✅ Extract error message từ backend response
- ✅ Handle các loại timeout errors
- ✅ Hiển thị message tiếng Việt cho user

### 2. Register Screen

**Khi email đã tồn tại (409):**
- Hiển thị: "Email đã tồn tại. Bạn có muốn đăng nhập không?"
- Thêm button "Đăng nhập ngay" để chuyển sang login screen

### 3. Error Messages

**Connection Timeout:**
```
"Connection timeout. Please check your internet connection."
```

**Server Timeout:**
```
"Server response timeout. Please try again."
```

**Email Exists (409):**
```
"Email đã tồn tại. Bạn có muốn đăng nhập không?"
```

**Invalid Credentials (401):**
```
"Invalid credentials" (từ backend)
```

---

## 📝 Error Codes

### 409 Conflict
- **Nguyên nhân:** Email đã tồn tại trong database
- **Giải pháp:** 
  - Đăng nhập thay vì đăng ký
  - Hoặc dùng email khác

### 401 Unauthorized
- **Nguyên nhân:** 
  - Email/password sai
  - Token expired
- **Giải pháp:**
  - Check lại email/password
  - Đăng nhập lại

### Connection Timeout
- **Nguyên nhân:**
  - Backend không chạy
  - Network issue
  - Firewall blocking
- **Giải pháp:**
  - Check backend đang chạy
  - Check network connection
  - Check firewall settings

---

## 🧪 Test Error Handling

### Test 1: Email đã tồn tại
1. Register với email: `test@example.com`
2. Register lại với cùng email
3. Sẽ thấy: "Email đã tồn tại. Bạn có muốn đăng nhập không?"
4. Click "Đăng nhập ngay" → Chuyển sang login screen

### Test 2: Connection Timeout
1. Stop backend
2. Thử Register
3. Sẽ thấy: "Connection timeout..."

### Test 3: Invalid Credentials
1. Login với email/password sai
2. Sẽ thấy: "Invalid credentials"

---

## 💡 Tips

1. **Luôn check error message** từ backend response
2. **Handle DioException** đúng cách
3. **Hiển thị message thân thiện** với user
4. **Thêm actions** (như "Đăng nhập ngay") khi có thể

---

## 🔄 Next Improvements

- [ ] Add retry mechanism cho network errors
- [ ] Add loading states tốt hơn
- [ ] Add offline detection
- [ ] Add error logging/reporting

