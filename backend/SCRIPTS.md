# 📜 Backend Scripts Guide

## 🚀 Available Scripts

### Development

#### `npm start` (Khuyến nghị)
```bash
npm start
```
- **Dùng:** `nodemon`
- **Tính năng:**
  - ✅ Auto-reload khi file thay đổi
  - ✅ Watch `src/` folder
  - ✅ Restart server tự động
  - ✅ Verbose logging
- **Khi nào dùng:** Development hàng ngày

#### `npm run start:dev`
```bash
npm run start:dev
```
- **Dùng:** `nest start --watch` (NestJS built-in watch)
- **Tính năng:**
  - ✅ Auto-reload khi file thay đổi
  - ✅ Fast compilation
- **Khi nào dùng:** Nếu nodemon có vấn đề

#### `npm run start:nodemon`
```bash
npm run start:nodemon
```
- **Dùng:** `nodemon` (giống `npm start`)
- **Khi nào dùng:** Backup option

#### `npm run start:debug`
```bash
npm run start:debug
```
- **Dùng:** `nest start --debug --watch`
- **Tính năng:** Debug mode với breakpoints
- **Khi nào dùng:** Khi cần debug

#### `npm run start:safe`
```bash
npm run start:safe
```
- **Dùng:** Node.js script tự động kill port 3000
- **Tính năng:**
  - ✅ Tự động kill process cũ
  - ✅ Start backend mới
- **Khi nào dùng:** Khi gặp lỗi "port already in use"

### Production

#### `npm run start:prod`
```bash
npm run start:prod
```
- **Dùng:** `node dist/main`
- **Tính năng:** Chạy compiled code
- **Khi nào dùng:** Production deployment

### Build

#### `npm run build`
```bash
npm run build
```
- Compile TypeScript → JavaScript
- Output: `dist/` folder

---

## 🔄 Nodemon vs NestJS Watch

### Nodemon (`npm start`)
**Ưu điểm:**
- ✅ Verbose logging (thấy rõ khi restart)
- ✅ Configurable (nodemon.json)
- ✅ Restart delay (tránh restart quá nhiều)
- ✅ Watch patterns linh hoạt

**Nhược điểm:**
- ⚠️ Có thể chậm hơn một chút

### NestJS Watch (`npm run start:dev`)
**Ưu điểm:**
- ✅ Fast compilation
- ✅ Built-in NestJS

**Nhược điểm:**
- ⚠️ Ít verbose hơn
- ⚠️ Ít configurable

---

## 📝 Nodemon Configuration

File: `nodemon.json`

```json
{
  "watch": ["src"],           // Watch folders
  "ext": "ts,json",          // Watch file extensions
  "ignore": [...],            // Ignore patterns
  "exec": "nest start",      // Command to run
  "verbose": true,           // Show detailed logs
  "restartable": "rs",       // Type 'rs' to restart manually
  "delay": 1000              // Wait 1s before restart
}
```

---

## 💡 Tips

1. **Dùng `npm start`** cho development hàng ngày
2. **Dùng `npm run start:safe`** nếu gặp port conflict
3. **Dùng `npm run start:dev`** nếu nodemon có vấn đề
4. **Type `rs` + Enter** trong nodemon để restart thủ công

---

## 🐛 Troubleshooting

### Nodemon không restart?
- Check `nodemon.json` config
- Check file có trong `watch` folder không
- Check file extension có trong `ext` list không

### NestJS watch không hoạt động?
- Check `nest-cli.json` config
- Try `npm run start:dev` thay vì `npm start`

### Port conflict?
- Dùng `npm run start:safe`
- Hoặc `start.bat` / `start.sh`

