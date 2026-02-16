/**
 * Seed: Xóa IC3 cũ, tạo lại IC3 mới (~60 bài) + Thêm bài cho Bóng rổ (~52 bài thêm)
 *
 * CÁCH CHẠY:
 *   cd backend
 *   npx ts-node -r tsconfig-paths/register src/seed/seed-ic3-basketball-expand.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { SubjectsService } from '../subjects/subjects.service';
import { DomainsService } from '../domains/domains.service';
import { TopicsService } from '../topics/topics.service';
import { LessonTypeContentsService } from '../lesson-type-contents/lesson-type-contents.service';
import { AiService } from '../ai/ai.service';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Subject } from '../subjects/entities/subject.entity';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

interface NodeDef {
  title: string;
  description: string;
  order: number;
  difficulty: 'easy' | 'medium' | 'hard';
  type: 'theory' | 'practice' | 'assessment';
  expReward: number;
  coinReward: number;
}

interface TopicDef {
  name: string;
  description: string;
  order: number;
  difficulty: 'easy' | 'medium' | 'hard';
  expReward: number;
  coinReward: number;
  nodes: NodeDef[];
}

interface DomainDef {
  name: string;
  description: string;
  order: number;
  difficulty: 'easy' | 'medium' | 'hard';
  expReward: number;
  coinReward: number;
  icon: string;
  topics: TopicDef[];
}

interface SubjectDef {
  name: string;
  description: string;
  track: 'explorer' | 'scholar';
  icon: string;
  color: string;
  domains: DomainDef[];
}

// ═══════════════════════════════════════════════════════════════
// IC3 SUBJECT (60 lessons)
// ═══════════════════════════════════════════════════════════════

const IC3_SUBJECT: SubjectDef = {
  name: 'IC3',
  description: 'Chứng chỉ Tin học Quốc tế IC3 - Internet and Computing Core Certification. Bao gồm kiến thức về phần cứng, phần mềm, mạng, Internet và các ứng dụng văn phòng.',
  track: 'scholar',
  icon: '💻',
  color: '#3B82F6',
  domains: [
    // ─── DOMAIN 1: Computing Fundamentals (15 bài) ───
    {
      name: 'Computing Fundamentals',
      description: 'Kiến thức cơ bản về máy tính: phần cứng, phần mềm, hệ điều hành',
      order: 0,
      difficulty: 'easy',
      expReward: 800,
      coinReward: 300,
      icon: '🖥️',
      topics: [
        {
          name: 'Phần cứng máy tính',
          description: 'Các thành phần phần cứng, cách hoạt động và bảo trì',
          order: 0, difficulty: 'easy', expReward: 300, coinReward: 100,
          nodes: [
            { title: 'Tổng quan về máy tính', description: 'Lịch sử phát triển máy tính, các thế hệ máy tính, phân loại máy tính (desktop, laptop, tablet, server)', order: 0, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'CPU - Bộ xử lý trung tâm', description: 'Cấu tạo CPU, xung nhịp, lõi, cache, các hãng Intel/AMD, so sánh hiệu năng', order: 1, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'RAM và bộ nhớ trong', description: 'RAM là gì, DDR4/DDR5, dung lượng, tốc độ, ROM, BIOS/UEFI', order: 2, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'Ổ cứng và lưu trữ', description: 'HDD vs SSD, NVMe, dung lượng, tốc độ đọc/ghi, RAID', order: 3, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'Thiết bị ngoại vi', description: 'Bàn phím, chuột, màn hình, máy in, scanner, webcam, loa, tai nghe', order: 4, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
          ],
        },
        {
          name: 'Hệ điều hành',
          description: 'Windows, macOS, Linux và các chức năng cơ bản',
          order: 1, difficulty: 'easy', expReward: 300, coinReward: 100,
          nodes: [
            { title: 'Hệ điều hành là gì?', description: 'Khái niệm OS, vai trò, các loại hệ điều hành phổ biến (Windows, macOS, Linux, Android, iOS)', order: 0, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'Giao diện Windows', description: 'Desktop, Taskbar, Start Menu, File Explorer, Settings, Control Panel', order: 1, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Quản lý file và thư mục', description: 'Tạo, sao chép, di chuyển, xóa file/folder, đường dẫn, phần mở rộng file', order: 2, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Cài đặt và gỡ phần mềm', description: 'Cách cài đặt ứng dụng, gỡ bỏ, cập nhật Windows Update, Store', order: 3, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
            { title: 'Bảo trì hệ thống', description: 'Disk Cleanup, Defragment, Task Manager, System Restore, Backup', order: 4, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
          ],
        },
        {
          name: 'Phần mềm ứng dụng',
          description: 'Các loại phần mềm và ứng dụng phổ biến',
          order: 2, difficulty: 'easy', expReward: 250, coinReward: 90,
          nodes: [
            { title: 'Phân loại phần mềm', description: 'Phần mềm hệ thống vs ứng dụng, freeware, shareware, open source, bản quyền', order: 0, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'Trình duyệt web', description: 'Chrome, Firefox, Edge, Safari - cách sử dụng, tab, bookmark, lịch sử, extension', order: 1, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Ứng dụng đa phương tiện', description: 'Phần mềm xem ảnh, nghe nhạc, xem video, chỉnh sửa ảnh cơ bản', order: 2, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'Nén file và giải nén', description: 'ZIP, RAR, 7z - cách nén, giải nén, tạo file nén có mật khẩu', order: 3, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Cloud Storage', description: 'Google Drive, OneDrive, Dropbox - lưu trữ đám mây, đồng bộ, chia sẻ file', order: 4, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
          ],
        },
      ],
    },
    // ─── DOMAIN 2: Key Applications (20 bài) ───
    {
      name: 'Key Applications',
      description: 'Ứng dụng văn phòng: Word, Excel, PowerPoint',
      order: 1,
      difficulty: 'medium',
      expReward: 1200,
      coinReward: 500,
      icon: '📄',
      topics: [
        {
          name: 'Microsoft Word',
          description: 'Soạn thảo văn bản chuyên nghiệp với Word',
          order: 0, difficulty: 'easy', expReward: 400, coinReward: 150,
          nodes: [
            { title: 'Giao diện Word và thao tác cơ bản', description: 'Ribbon, Quick Access, tạo/mở/lưu tài liệu, các chế độ xem', order: 0, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Định dạng văn bản', description: 'Font, cỡ chữ, bold/italic/underline, màu chữ, highlight, Format Painter', order: 1, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Định dạng đoạn văn', description: 'Căn lề, khoảng cách dòng, thụt đầu dòng, bullet/numbering, Styles', order: 2, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Chèn hình ảnh và bảng', description: 'Insert Picture, Table, Shape, SmartArt, Chart, WordArt', order: 3, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
            { title: 'Header, Footer và đánh số trang', description: 'Header/Footer, Page Number, Section Break, Cover Page', order: 4, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
            { title: 'Tìm kiếm và thay thế', description: 'Find & Replace, Go To, Navigation Pane, Spell Check', order: 5, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'In ấn và xuất file', description: 'Page Setup, Print Preview, Print, Save as PDF, chia sẻ tài liệu', order: 6, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
          ],
        },
        {
          name: 'Microsoft Excel',
          description: 'Bảng tính và phân tích dữ liệu với Excel',
          order: 1, difficulty: 'medium', expReward: 500, coinReward: 200,
          nodes: [
            { title: 'Giao diện Excel và ô tính', description: 'Workbook, Worksheet, Cell, Row, Column, Range, Name Box, Formula Bar', order: 0, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Nhập liệu và định dạng ô', description: 'Nhập số, text, ngày tháng, định dạng Number/Date/Currency, Merge Cells', order: 1, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Công thức cơ bản', description: 'SUM, AVERAGE, COUNT, MAX, MIN, phép tính +, -, *, /, tham chiếu ô', order: 2, difficulty: 'easy', type: 'practice', expReward: 60, coinReward: 25 },
            { title: 'Hàm IF và hàm logic', description: 'IF, AND, OR, NOT, IF lồng nhau, COUNTIF, SUMIF', order: 3, difficulty: 'medium', type: 'practice', expReward: 70, coinReward: 30 },
            { title: 'Hàm VLOOKUP và HLOOKUP', description: 'VLOOKUP, HLOOKUP, INDEX-MATCH, tham chiếu tuyệt đối/tương đối', order: 4, difficulty: 'medium', type: 'practice', expReward: 80, coinReward: 30 },
            { title: 'Sắp xếp và lọc dữ liệu', description: 'Sort A-Z/Z-A, Custom Sort, AutoFilter, Advanced Filter', order: 5, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
            { title: 'Biểu đồ trong Excel', description: 'Column Chart, Line Chart, Pie Chart, Bar Chart, tùy chỉnh biểu đồ', order: 6, difficulty: 'medium', type: 'practice', expReward: 70, coinReward: 30 },
            { title: 'Định dạng có điều kiện', description: 'Conditional Formatting: Highlight Cells, Data Bars, Color Scales, Icon Sets', order: 7, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
          ],
        },
        {
          name: 'Microsoft PowerPoint',
          description: 'Tạo bài thuyết trình chuyên nghiệp',
          order: 2, difficulty: 'easy', expReward: 300, coinReward: 120,
          nodes: [
            { title: 'Giao diện PowerPoint', description: 'Slide, Slide Panel, Notes, các chế độ xem Normal/Slide Sorter/Reading', order: 0, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Tạo và thiết kế slide', description: 'Slide Layout, Theme, Background, Slide Master, chèn text box', order: 1, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Chèn nội dung đa phương tiện', description: 'Hình ảnh, video, audio, bảng, biểu đồ, SmartArt, Icons', order: 2, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Animation và Transition', description: 'Hiệu ứng chuyển slide, animation cho đối tượng, timing, trigger', order: 3, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
            { title: 'Trình chiếu và xuất file', description: 'Slide Show, Presenter View, xuất PDF, video, chia sẻ online', order: 4, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
          ],
        },
      ],
    },
    // ─── DOMAIN 3: Living Online (15 bài) ───
    {
      name: 'Living Online',
      description: 'Internet, email, mạng xã hội và an toàn trực tuyến',
      order: 2,
      difficulty: 'medium',
      expReward: 800,
      coinReward: 350,
      icon: '🌐',
      topics: [
        {
          name: 'Internet và Mạng máy tính',
          description: 'Kiến thức về Internet, mạng LAN/WAN, kết nối',
          order: 0, difficulty: 'easy', expReward: 250, coinReward: 100,
          nodes: [
            { title: 'Internet là gì?', description: 'Lịch sử Internet, WWW, cách Internet hoạt động, ISP, băng thông', order: 0, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'Mạng máy tính cơ bản', description: 'LAN, WAN, Wi-Fi, Ethernet, Router, Modem, Switch, IP Address', order: 1, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'Tìm kiếm trên Internet', description: 'Google Search, toán tử tìm kiếm, đánh giá nguồn tin, tránh thông tin sai', order: 2, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'URL và tên miền', description: 'Cấu trúc URL, HTTP/HTTPS, DNS, tên miền .com .vn .org, hosting', order: 3, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
          ],
        },
        {
          name: 'Email và Giao tiếp trực tuyến',
          description: 'Sử dụng email, chat, video call chuyên nghiệp',
          order: 1, difficulty: 'easy', expReward: 250, coinReward: 100,
          nodes: [
            { title: 'Sử dụng Email', description: 'Tạo tài khoản Gmail, gửi/nhận email, CC/BCC, đính kèm file, chữ ký email', order: 0, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Quản lý hộp thư', description: 'Label, Filter, Star, Archive, Spam, Search email, cài đặt', order: 1, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Giao tiếp trực tuyến', description: 'Zoom, Google Meet, Microsoft Teams, chat, video call, screen sharing', order: 2, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Lịch và công cụ cộng tác', description: 'Google Calendar, Google Docs, Microsoft 365 Online, chia sẻ và cộng tác', order: 3, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
          ],
        },
        {
          name: 'An toàn trực tuyến',
          description: 'Bảo mật, quyền riêng tư và sử dụng Internet an toàn',
          order: 2, difficulty: 'medium', expReward: 300, coinReward: 120,
          nodes: [
            { title: 'Mật khẩu và xác thực', description: 'Tạo mật khẩu mạnh, 2FA, password manager, không chia sẻ mật khẩu', order: 0, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
            { title: 'Virus và Malware', description: 'Virus, worm, trojan, ransomware, spyware, cách phòng tránh, antivirus', order: 1, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
            { title: 'Lừa đảo trực tuyến', description: 'Phishing, scam email, giả mạo website, social engineering, cách nhận biết', order: 2, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
            { title: 'Quyền riêng tư và Pháp luật', description: 'Bảo vệ thông tin cá nhân, cookies, quyền riêng tư trên mạng xã hội, luật CNTT', order: 3, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
            { title: 'Đạo đức và bản quyền số', description: 'Bản quyền phần mềm, Creative Commons, netiquette, cyberbullying, digital footprint', order: 4, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
            { title: 'Sao lưu và khôi phục dữ liệu', description: 'Backup cục bộ, cloud backup, khôi phục file, các phương pháp sao lưu 3-2-1', order: 5, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
          ],
        },
      ],
    },
    // ─── DOMAIN 4: Kỹ năng nâng cao (10 bài) ───
    {
      name: 'Kỹ năng nâng cao',
      description: 'Kỹ năng tin học nâng cao: Excel nâng cao, Google Workspace, AI',
      order: 3,
      difficulty: 'hard',
      expReward: 600,
      coinReward: 250,
      icon: '🚀',
      topics: [
        {
          name: 'Excel nâng cao',
          description: 'Pivot Table, Macro, hàm nâng cao',
          order: 0, difficulty: 'hard', expReward: 300, coinReward: 120,
          nodes: [
            { title: 'Pivot Table', description: 'Tạo PivotTable, kéo thả trường, tính toán, lọc, slicer, PivotChart', order: 0, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
            { title: 'Hàm TEXT và DATE nâng cao', description: 'LEFT, RIGHT, MID, CONCATENATE, TEXT, DATEDIF, EOMONTH, NETWORKDAYS', order: 1, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
            { title: 'Data Validation', description: 'Tạo dropdown list, giới hạn nhập liệu, custom validation, error alert', order: 2, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
            { title: 'Bảo vệ và chia sẻ Workbook', description: 'Protect Sheet, Protect Workbook, mật khẩu mở file, Track Changes, Comment', order: 3, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
            { title: 'Macro cơ bản', description: 'Record Macro, chạy macro, VBA cơ bản, tự động hóa tác vụ lặp lại', order: 4, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
          ],
        },
        {
          name: 'Công cụ AI và Tương lai',
          description: 'ChatGPT, AI trong công việc, xu hướng công nghệ',
          order: 1, difficulty: 'medium', expReward: 300, coinReward: 120,
          nodes: [
            { title: 'AI trong đời sống', description: 'ChatGPT, Google Gemini, AI trong tìm kiếm, dịch thuật, viết văn bản', order: 0, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
            { title: 'Sử dụng ChatGPT hiệu quả', description: 'Viết prompt, ứng dụng trong học tập, công việc, hạn chế và lưu ý đạo đức', order: 1, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
            { title: 'Google Workspace', description: 'Google Docs, Sheets, Slides, Forms, Drive - làm việc cộng tác đám mây', order: 2, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
            { title: 'Xu hướng công nghệ', description: 'IoT, Cloud Computing, Big Data, Blockchain, thực tế ảo VR/AR', order: 3, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
            { title: 'Kỹ năng số cho nghề nghiệp', description: 'Digital literacy, remote work, portfolio online, LinkedIn, freelance', order: 4, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
          ],
        },
      ],
    },
  ],
};

// ═══════════════════════════════════════════════════════════════
// BASKETBALL EXPANSION (thêm bài cho Bóng rổ)
// ═══════════════════════════════════════════════════════════════

const BASKETBALL_NEW_DOMAINS: DomainDef[] = [
  // ─── DOMAIN 3: Thể lực & Dinh dưỡng (12 bài) ───
  {
    name: 'Thể lực & Dinh dưỡng',
    description: 'Rèn luyện thể lực, dinh dưỡng và phòng tránh chấn thương cho bóng rổ',
    order: 2, difficulty: 'medium', expReward: 600, coinReward: 250, icon: '💪',
    topics: [
      {
        name: 'Thể lực cho bóng rổ',
        description: 'Bài tập sức mạnh, tốc độ, sức bền cho cầu thủ bóng rổ',
        order: 0, difficulty: 'medium', expReward: 300, coinReward: 120,
        nodes: [
          { title: 'Sức mạnh chân và nhảy cao', description: 'Bài tập squat, lunge, box jump, calf raise để tăng sức bật và nhảy cao', order: 0, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
          { title: 'Sức bền tim mạch', description: 'Chạy interval, shuttle run, suicides drill, phương pháp tăng sức bền', order: 1, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
          { title: 'Tốc độ và phản xạ', description: 'Agility ladder, cone drill, phản xạ tay-mắt, bài tập phối hợp', order: 2, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
          { title: 'Sức mạnh core và thân trên', description: 'Plank, situp, pushup, pull-up, tầm quan trọng core trong bóng rổ', order: 3, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
          { title: 'Khởi động và giãn cơ', description: 'Bài tập khởi động trước trận, giãn cơ sau tập, mobility exercises', order: 4, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
          { title: 'Lịch tập luyện hàng tuần', description: 'Thiết kế lịch tập 5 ngày/tuần, phân chia nhóm cơ, ngày nghỉ', order: 5, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
        ],
      },
      {
        name: 'Dinh dưỡng và Phục hồi',
        description: 'Chế độ ăn uống, nghỉ ngơi và phòng tránh chấn thương',
        order: 1, difficulty: 'easy', expReward: 300, coinReward: 120,
        nodes: [
          { title: 'Dinh dưỡng cho vận động viên', description: 'Carbs, protein, chất béo, vitamin, chế độ ăn trước/sau tập', order: 0, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
          { title: 'Nước và điện giải', description: 'Uống nước đúng cách, nước ion, tránh mất nước khi thi đấu', order: 1, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
          { title: 'Phòng tránh chấn thương', description: 'Bong gân mắt cá, chấn thương đầu gối, ACL, cách bảo vệ', order: 2, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
          { title: 'Sơ cứu chấn thương thể thao', description: 'RICE method, khi nào cần đi bác sĩ, phục hồi sau chấn thương', order: 3, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
          { title: 'Giấc ngủ và phục hồi', description: 'Tầm quan trọng giấc ngủ, foam rolling, massage, ice bath', order: 4, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
          { title: 'Tâm lý thi đấu', description: 'Tập trung, kiểm soát áp lực, visualization, self-talk tích cực', order: 5, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
        ],
      },
    ],
  },
  // ─── DOMAIN 4: Kỹ thuật nâng cao (14 bài) ───
  {
    name: 'Kỹ thuật nâng cao',
    description: 'Kỹ thuật chuyên sâu: ném rổ nâng cao, chuyền bóng, di chuyển',
    order: 3, difficulty: 'hard', expReward: 800, coinReward: 350, icon: '🎯',
    topics: [
      {
        name: 'Ném rổ nâng cao',
        description: 'Kỹ thuật ném 3 điểm, mid-range, floater, hook shot',
        order: 0, difficulty: 'hard', expReward: 400, coinReward: 150,
        nodes: [
          { title: 'Ném 3 điểm chuyên sâu', description: 'Tư thế, release point, follow through, catch-and-shoot, off-the-dribble 3', order: 0, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
          { title: 'Mid-range Game', description: 'Pull-up jumper, fadeaway, step-back, turn-around jumper', order: 1, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
          { title: 'Floater và Tear Drop', description: 'Kỹ thuật floater qua tầm block, khi nào dùng, tập luyện', order: 2, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
          { title: 'Hook Shot và Sky Hook', description: 'Baby hook, running hook, sky hook kiểu Kareem Abdul-Jabbar', order: 3, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
          { title: 'Ném phạt - Kỹ thuật và Tâm lý', description: 'Free throw routine, tư thế chuẩn, tập trung tinh thần, clutch shooting', order: 4, difficulty: 'medium', type: 'practice', expReward: 70, coinReward: 30 },
        ],
      },
      {
        name: 'Chuyền bóng và phối hợp',
        description: 'Kỹ thuật chuyền bóng và phối hợp đồng đội',
        order: 1, difficulty: 'medium', expReward: 250, coinReward: 100,
        nodes: [
          { title: 'Chuyền bóng cơ bản', description: 'Chest pass, bounce pass, overhead pass, baseball pass', order: 0, difficulty: 'easy', type: 'practice', expReward: 50, coinReward: 20 },
          { title: 'No-look pass và Behind-the-back', description: 'Chuyền bóng sáng tạo, khi nào nên dùng, rủi ro và lợi ích', order: 1, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
          { title: 'Alley-oop và Lob pass', description: 'Kỹ thuật ném bóng bổng cho đồng đội ghi điểm, timing và phối hợp', order: 2, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
          { title: 'Entry pass vào vùng cấm', description: 'Post entry pass, kỹ thuật chuyền cho center, tránh bị cắt bóng', order: 3, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
        ],
      },
      {
        name: 'Di chuyển và tạo khoảng trống',
        description: 'Footwork, di chuyển không bóng, tạo space',
        order: 2, difficulty: 'medium', expReward: 300, coinReward: 120,
        nodes: [
          { title: 'Footwork cơ bản', description: 'Pivot, jab step, triple threat, drop step, spin move', order: 0, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
          { title: 'Di chuyển không bóng', description: 'Cutting (V-cut, L-cut, backdoor), di chuyển để nhận bóng, spacing', order: 1, difficulty: 'medium', type: 'practice', expReward: 60, coinReward: 25 },
          { title: 'Screen và Off-ball Screen', description: 'Cách đặt screen, slip screen, flare screen, down screen', order: 2, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
          { title: 'Euro Step và Jelly Layup', description: 'Euro step qua hậu vệ, jelly/finger roll, reverse layup, power layup', order: 3, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
          { title: 'Post Moves', description: 'Drop step, up-and-under, face-up game, Hakeem Olajuwon moves', order: 4, difficulty: 'hard', type: 'practice', expReward: 80, coinReward: 30 },
        ],
      },
    ],
  },
  // ─── DOMAIN 5: Chiến thuật nâng cao & Lịch sử (14 bài) ───
  {
    name: 'Chiến thuật nâng cao & Lịch sử',
    description: 'Hệ thống chiến thuật đội hình, phòng thủ nâng cao và lịch sử bóng rổ',
    order: 4, difficulty: 'hard', expReward: 800, coinReward: 350, icon: '📋',
    topics: [
      {
        name: 'Hệ thống tấn công',
        description: 'Triangle offense, motion offense, iso play',
        order: 0, difficulty: 'hard', expReward: 300, coinReward: 120,
        nodes: [
          { title: 'Triangle Offense', description: 'Hệ thống triangle của Phil Jackson, nguyên lý, ưu/nhược điểm', order: 0, difficulty: 'hard', type: 'theory', expReward: 80, coinReward: 30 },
          { title: 'Motion Offense', description: 'Hệ thống motion, ball movement, player movement, read and react', order: 1, difficulty: 'hard', type: 'theory', expReward: 80, coinReward: 30 },
          { title: 'Iso Play và 1-on-1', description: 'Isolation play, khi nào cần iso, cách tạo mismatch, clearout', order: 2, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
          { title: 'Transition Offense', description: 'Phản công nhanh, early offense, secondary break, numbers advantage', order: 3, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
        ],
      },
      {
        name: 'Phòng thủ nâng cao',
        description: 'Zone defense, press defense, help defense',
        order: 1, difficulty: 'hard', expReward: 300, coinReward: 120,
        nodes: [
          { title: 'Zone Defense (2-3, 3-2)', description: 'Phòng thủ khu vực 2-3, 3-2, ưu nhược điểm, khi nào dùng', order: 0, difficulty: 'hard', type: 'theory', expReward: 80, coinReward: 30 },
          { title: 'Full-court Press', description: 'Phòng thủ toàn sân, trap, diamond press, 1-2-1-1 press', order: 1, difficulty: 'hard', type: 'theory', expReward: 80, coinReward: 30 },
          { title: 'Help Defense và Rotation', description: 'Phòng thủ hỗ trợ, closeout, rotation, shell drill', order: 2, difficulty: 'medium', type: 'practice', expReward: 70, coinReward: 30 },
          { title: 'Chặn bóng và cướp bóng', description: 'Shot block technique, steal, passing lane, anticipation', order: 3, difficulty: 'medium', type: 'practice', expReward: 70, coinReward: 30 },
        ],
      },
      {
        name: 'Lịch sử bóng rổ',
        description: 'Nguồn gốc, phát triển và các huyền thoại',
        order: 2, difficulty: 'easy', expReward: 250, coinReward: 100,
        nodes: [
          { title: 'Nguồn gốc bóng rổ', description: 'James Naismith, 1891, luật gốc 13 điều, phát triển ban đầu', order: 0, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
          { title: 'NBA và các giải đấu lớn', description: 'Lịch sử NBA, FIBA, EuroLeague, giải bóng rổ Việt Nam VBA', order: 1, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
          { title: 'Huyền thoại bóng rổ', description: 'Michael Jordan, LeBron James, Kobe Bryant, Magic Johnson, Larry Bird', order: 2, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
          { title: 'Chiến thuật qua các thời kỳ', description: 'Từ big man era đến small ball, 3-point revolution, positionless basketball', order: 3, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
          { title: 'Bóng rổ tại Việt Nam', description: 'VBA League, các đội bóng Việt Nam, phát triển bóng rổ phong trào, Saigon Heat', order: 4, difficulty: 'easy', type: 'theory', expReward: 50, coinReward: 20 },
          { title: 'Luật thi đấu nâng cao', description: 'Shot clock, backcourt violation, flagrant foul, technical foul, challenge', order: 5, difficulty: 'medium', type: 'theory', expReward: 60, coinReward: 25 },
        ],
      },
    ],
  },
];

// ═══════════════════════════════════════════════════════════════
// MEDIA HELPERS
// ═══════════════════════════════════════════════════════════════

const SAMPLE_VIDEOS = [
  'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
];

function imageUrl(seed: string, w = 800, h = 600): string {
  return `https://picsum.photos/seed/${seed}/${w}/${h}`;
}

function videoUrl(index: number): string {
  return SAMPLE_VIDEOS[index % SAMPLE_VIDEOS.length];
}

// ═══════════════════════════════════════════════════════════════
// AI CONTENT GENERATION
// ═══════════════════════════════════════════════════════════════

async function generateAllLessonTypes(
  aiService: AiService,
  subjectName: string,
  nodeTitle: string,
  nodeDescription: string,
  nodeIndex: number,
): Promise<Record<string, { lessonData: any; endQuiz: any }>> {
  const slug = subjectName.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '');
  const imgBase = `${slug}-${nodeIndex}`;

  const prompt = `
Bạn là chuyên gia giáo dục. Hãy tạo nội dung bài học BẰNG TIẾNG VIỆT cho chủ đề sau:

Môn học: ${subjectName}
Bài học: ${nodeTitle}
Mô tả: ${nodeDescription}

Tạo nội dung cho ĐẦY ĐỦ 4 dạng bài học, trả về JSON theo format:

{
  "image_quiz": {
    "slides": [
      {
        "question": "Câu hỏi liên quan đến hình ảnh",
        "options": [
          { "text": "Đáp án A", "explanation": "Giải thích A" },
          { "text": "Đáp án B", "explanation": "Giải thích B" },
          { "text": "Đáp án C", "explanation": "Giải thích C" },
          { "text": "Đáp án D", "explanation": "Giải thích D" }
        ],
        "correctAnswer": 0,
        "hint": "Gợi ý"
      }
    ],
    "endQuiz": {
      "questions": [
        {
          "question": "Câu hỏi ôn tập",
          "options": [
            { "text": "A", "explanation": "..." },
            { "text": "B", "explanation": "..." },
            { "text": "C", "explanation": "..." },
            { "text": "D", "explanation": "..." }
          ],
          "correctAnswer": 0
        }
      ],
      "passingScore": 70
    }
  },
  "image_gallery": {
    "images": [
      { "description": "Mô tả chi tiết cho hình ảnh minh họa" }
    ],
    "endQuiz": {
      "questions": [...],
      "passingScore": 70
    }
  },
  "video": {
    "summary": "Tóm tắt nội dung video",
    "keyPoints": [
      { "title": "Tiêu đề", "description": "Chi tiết", "timestamp": 0 }
    ],
    "keywords": ["từ khóa 1", "từ khóa 2"],
    "endQuiz": {
      "questions": [...],
      "passingScore": 70
    }
  },
  "text": {
    "sections": [
      {
        "title": "Tiêu đề phần",
        "content": "Nội dung chi tiết (có thể dài)",
        "examples": [
          { "type": "real_world_scenario", "title": "Tiêu đề ví dụ", "content": "Nội dung ví dụ chi tiết" }
        ]
      }
    ],
    "inlineQuizzes": [
      {
        "afterSectionIndex": 0,
        "question": "Câu hỏi xen kẽ",
        "options": [
          { "text": "A", "explanation": "..." },
          { "text": "B", "explanation": "..." },
          { "text": "C", "explanation": "..." },
          { "text": "D", "explanation": "..." }
        ],
        "correctAnswer": 0
      }
    ],
    "summary": "Tóm tắt bài học",
    "learningObjectives": ["Mục tiêu 1", "Mục tiêu 2"],
    "endQuiz": {
      "questions": [...],
      "passingScore": 70
    }
  }
}

YÊU CẦU:
- image_quiz: Tạo 4-5 slides, mỗi slide 1 câu hỏi với 4 đáp án, endQuiz 5 câu
- image_gallery: Tạo 5-6 images với mô tả chi tiết, endQuiz 5 câu
- video: Tạo summary, 4-5 keyPoints với timestamp tăng dần (giây), 5 keywords, endQuiz 5 câu
- text: Tạo 3-4 sections nội dung chi tiết, mỗi section có 1-2 examples (loại: real_world_scenario, everyday_analogy, step_by_step, comparison, story_narrative), 2 inlineQuizzes, summary, 3 learningObjectives, endQuiz 5 câu
- Mỗi endQuiz có ĐÚNG 5 câu hỏi, mỗi câu 4 đáp án
- correctAnswer là index (0-3)
- Nội dung phải chính xác, hữu ích, phù hợp trình độ người học
- KHÔNG thêm imageUrl hay videoUrl, chỉ tạo nội dung text
- Trả về JSON hợp lệ, KHÔNG markdown
`;

  console.log(`    🤖 Đang gọi AI tạo nội dung cho "${nodeTitle}"...`);
  const raw = await aiService.chatWithJsonMode([
    { role: 'user', content: prompt },
  ]);

  const data = JSON.parse(raw);

  // Inject media URLs
  if (data.image_quiz?.slides) {
    data.image_quiz.slides = data.image_quiz.slides.map((slide: any, i: number) => ({
      ...slide,
      imageUrl: imageUrl(`${imgBase}-quiz-${i}`),
    }));
  }
  if (data.image_gallery?.images) {
    data.image_gallery.images = data.image_gallery.images.map((img: any, i: number) => ({
      ...img,
      url: imageUrl(`${imgBase}-gallery-${i}`),
    }));
  }
  if (data.video) {
    data.video.videoUrl = videoUrl(nodeIndex);
  }

  // Build result
  const result: Record<string, { lessonData: any; endQuiz: any }> = {};

  result['image_quiz'] = {
    lessonData: { slides: data.image_quiz?.slides || [] },
    endQuiz: data.image_quiz?.endQuiz || { questions: [], passingScore: 70 },
  };
  result['image_gallery'] = {
    lessonData: { images: data.image_gallery?.images || [] },
    endQuiz: data.image_gallery?.endQuiz || { questions: [], passingScore: 70 },
  };
  result['video'] = {
    lessonData: {
      videoUrl: data.video?.videoUrl || '',
      summary: data.video?.summary || '',
      keyPoints: data.video?.keyPoints || [],
      keywords: data.video?.keywords || [],
    },
    endQuiz: data.video?.endQuiz || { questions: [], passingScore: 70 },
  };
  result['text'] = {
    lessonData: {
      sections: data.text?.sections || [],
      inlineQuizzes: data.text?.inlineQuizzes || [],
      summary: data.text?.summary || '',
      learningObjectives: data.text?.learningObjectives || [],
    },
    endQuiz: data.text?.endQuiz || { questions: [], passingScore: 70 },
  };

  return result;
}

// ═══════════════════════════════════════════════════════════════
// HELPER: Delete subject completely
// ═══════════════════════════════════════════════════════════════

async function deleteSubjectCompletely(
  nodeRepo: Repository<LearningNode>,
  subjectRepo: Repository<Subject>,
  subjectId: string,
): Promise<void> {
  const mgr = nodeRepo.manager;
  // Cascade delete in correct order
  await mgr.query(`DELETE FROM lesson_type_contents WHERE "nodeId" IN (SELECT id FROM learning_nodes WHERE "subjectId" = $1)`, [subjectId]).catch(() => {});
  await mgr.query(`DELETE FROM lesson_type_content_versions WHERE "nodeId" IN (SELECT id FROM learning_nodes WHERE "subjectId" = $1)`, [subjectId]).catch(() => {});
  await mgr.query(`DELETE FROM user_progress WHERE "nodeId" IN (SELECT id FROM learning_nodes WHERE "subjectId" = $1)`, [subjectId]).catch(() => {});
  await mgr.query(`DELETE FROM personal_mind_maps WHERE "subjectId" = $1`, [subjectId]).catch(() => {});
  await mgr.query(`DELETE FROM adaptive_tests WHERE "subjectId" = $1`, [subjectId]).catch(() => {});
  await mgr.query(`DELETE FROM learning_nodes WHERE "subjectId" = $1`, [subjectId]);
  await mgr.query(`DELETE FROM topics WHERE "domainId" IN (SELECT id FROM domains WHERE "subjectId" = $1)`, [subjectId]);
  await mgr.query(`DELETE FROM domains WHERE "subjectId" = $1`, [subjectId]);
  await subjectRepo.delete(subjectId);
}

// ═══════════════════════════════════════════════════════════════
// HELPER: Create domains/topics/nodes for a subject
// ═══════════════════════════════════════════════════════════════

async function createDomainsForSubject(
  subjectId: string,
  subjectName: string,
  subjectIcon: string,
  domains: DomainDef[],
  domainsService: any,
  topicsService: any,
  lessonTypeContentsService: any,
  aiService: AiService,
  nodeRepo: Repository<LearningNode>,
  startNodeIndex: number,
): Promise<number> {
  let globalNodeIndex = startNodeIndex;

  for (const domainDef of domains) {
    console.log(`\n  📂 Domain: ${domainDef.name}`);
    const domain = await domainsService.create(subjectId, {
      name: domainDef.name,
      description: domainDef.description,
      order: domainDef.order,
      difficulty: domainDef.difficulty,
      expReward: domainDef.expReward,
      coinReward: domainDef.coinReward,
      metadata: { icon: domainDef.icon },
    });
    console.log(`    ✅ Domain ID: ${domain.id}`);

    for (const topicDef of domainDef.topics) {
      console.log(`\n    📌 Topic: ${topicDef.name}`);
      const topic = await topicsService.create(domain.id, {
        name: topicDef.name,
        description: topicDef.description,
        order: topicDef.order,
        difficulty: topicDef.difficulty,
        expReward: topicDef.expReward,
        coinReward: topicDef.coinReward,
      });
      console.log(`      ✅ Topic ID: ${topic.id}`);

      for (const nodeDef of topicDef.nodes) {
        console.log(`\n      📖 Node: ${nodeDef.title}`);
        const node = nodeRepo.create({
          subjectId,
          domainId: domain.id,
          topicId: topic.id,
          title: nodeDef.title,
          description: nodeDef.description,
          order: nodeDef.order,
          type: nodeDef.type,
          difficulty: nodeDef.difficulty,
          expReward: nodeDef.expReward,
          coinReward: nodeDef.coinReward,
          prerequisites: [],
          contentStructure: { concepts: 4, examples: 10, hiddenRewards: 5, bossQuiz: 1 },
          metadata: {
            icon: subjectIcon,
            position: { x: nodeDef.order * 200, y: domainDef.order * 300 + topicDef.order * 150 },
          },
        });
        const savedNode = await nodeRepo.save(node);
        console.log(`        ✅ Node ID: ${savedNode.id}`);

        // Generate AI content
        try {
          const allTypes = await generateAllLessonTypes(
            aiService, subjectName, nodeDef.title, nodeDef.description, globalNodeIndex,
          );
          const types: Array<'image_quiz' | 'image_gallery' | 'video' | 'text'> = ['image_quiz', 'image_gallery', 'video', 'text'];
          for (const lt of types) {
            const content = allTypes[lt];
            if (!content) { console.log(`        ⚠️  Thiếu nội dung cho dạng ${lt}`); continue; }
            try {
              await lessonTypeContentsService.create({
                nodeId: savedNode.id, lessonType: lt, lessonData: content.lessonData, endQuiz: content.endQuiz,
              });
              console.log(`        ✅ ${lt} - OK`);
            } catch (err: any) {
              console.log(`        ❌ ${lt} - Lỗi: ${err.message?.substring(0, 80)}`);
            }
          }
          savedNode.lessonType = 'text';
          savedNode.lessonData = allTypes['text']?.lessonData || {};
          savedNode.endQuiz = allTypes['text']?.endQuiz || null;
          await nodeRepo.save(savedNode);
        } catch (err: any) {
          console.log(`        ❌ AI generation failed: ${err.message?.substring(0, 120)}`);
        }
        globalNodeIndex++;
      }
    }
  }
  return globalNodeIndex;
}

// ═══════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════

async function seed() {
  console.log('═══════════════════════════════════════════════════');
  console.log('  SEED: Tạo lại IC3 (60 bài) + Mở rộng Bóng rổ (+52 bài)');
  console.log('═══════════════════════════════════════════════════\n');

  const app = await NestFactory.createApplicationContext(AppModule);

  const subjectsService = app.get(SubjectsService);
  const domainsService = app.get(DomainsService);
  const topicsService = app.get(TopicsService);
  const lessonTypeContentsService = app.get(LessonTypeContentsService);
  const aiService = app.get(AiService);
  const nodeRepo = app.get<Repository<LearningNode>>(getRepositoryToken(LearningNode));
  const subjectRepo = app.get<Repository<Subject>>(getRepositoryToken(Subject));

  let globalNodeIndex = 0;

  // ═══ PART 1: Xóa IC3 cũ và tạo lại ═══
  console.log('\n🔴 PART 1: XÓA IC3 CŨ VÀ TẠO LẠI');
  console.log('━'.repeat(50));

  const existingIC3 = await subjectRepo.findOne({ where: { name: 'Ic3' } });
  if (existingIC3) {
    console.log(`  🗑️  Đang xóa IC3 cũ (${existingIC3.id})...`);
    await deleteSubjectCompletely(nodeRepo, subjectRepo, existingIC3.id);
    console.log('  ✅ Đã xóa sạch IC3 cũ.');
  }

  // Also try "IC3" with different casing
  const existingIC3_2 = await subjectRepo.findOne({ where: { name: 'IC3' } });
  if (existingIC3_2) {
    console.log(`  🗑️  Đang xóa IC3 cũ (${existingIC3_2.id})...`);
    await deleteSubjectCompletely(nodeRepo, subjectRepo, existingIC3_2.id);
    console.log('  ✅ Đã xóa sạch IC3 cũ.');
  }

  // Create new IC3
  const ic3Subject = await subjectsService.createIfNotExists(
    IC3_SUBJECT.name, IC3_SUBJECT.description, IC3_SUBJECT.track,
  );
  ic3Subject.metadata = { icon: IC3_SUBJECT.icon, color: IC3_SUBJECT.color, estimatedDays: 60 };
  ic3Subject.unlockConditions = { minCoin: 0 };
  await subjectRepo.save(ic3Subject);
  console.log(`  ✅ Tạo IC3 mới: ${ic3Subject.id}`);

  globalNodeIndex = await createDomainsForSubject(
    ic3Subject.id, IC3_SUBJECT.name, IC3_SUBJECT.icon, IC3_SUBJECT.domains,
    domainsService, topicsService, lessonTypeContentsService, aiService, nodeRepo, globalNodeIndex,
  );

  const ic3Count = globalNodeIndex;
  console.log(`\n  📊 IC3: ${ic3Count} bài học đã tạo`);

  // ═══ PART 2: Mở rộng Bóng rổ ═══
  console.log('\n🟠 PART 2: MỞ RỘNG BÓNG RỔ');
  console.log('━'.repeat(50));

  const basketballSubject = await subjectRepo.findOne({ where: { name: 'Bóng rổ' } });
  if (!basketballSubject) {
    console.log('  ❌ Không tìm thấy môn Bóng rổ!');
    await app.close();
    return;
  }

  console.log(`  ✅ Tìm thấy Bóng rổ: ${basketballSubject.id}`);
  console.log('  📌 Thêm 3 domain mới (Thể lực, Kỹ thuật nâng cao, Chiến thuật & Lịch sử)...');

  const beforeIndex = globalNodeIndex;
  globalNodeIndex = await createDomainsForSubject(
    basketballSubject.id, 'Bóng rổ', '🏀', BASKETBALL_NEW_DOMAINS,
    domainsService, topicsService, lessonTypeContentsService, aiService, nodeRepo, globalNodeIndex,
  );

  const basketballNewCount = globalNodeIndex - beforeIndex;
  console.log(`\n  📊 Bóng rổ: +${basketballNewCount} bài học mới (tổng ~${basketballNewCount + 8} bài)`);

  // ═══ SUMMARY ═══
  console.log('\n═══════════════════════════════════════════════════');
  console.log('  ✅ SEED HOÀN THÀNH!');
  console.log(`  IC3: ${ic3Count} bài học`);
  console.log(`  Bóng rổ: +${basketballNewCount} bài (tổng ~${basketballNewCount + 8})`);
  console.log(`  Tổng nodes xử lý: ${globalNodeIndex}`);
  console.log('═══════════════════════════════════════════════════\n');

  await app.close();
}

seed().catch((err) => {
  console.error('❌ Seed thất bại:', err);
  process.exit(1);
});
