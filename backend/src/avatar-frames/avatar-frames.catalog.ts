/**
 * 20 khung avatar — tier càng cao (chi tiết / giá) càng “premium”.
 * paymentMode:
 * - coins: chỉ GTU
 * - diamonds: chỉ kim cương
 * - choice: mua bằng GTU hoặc kim cương (client chọn trước khi mua)
 */

export type AvatarFramePaymentMode = 'coins' | 'diamonds' | 'choice';

export interface AvatarFrameDefinition {
  id: string;
  name: string;
  description: string;
  /** 1–20 — độ “hoành tráng” & giá tham chiếu UI. */
  tier: number;
  /** Level tối thiểu để được phép mua (vẫn hiện trong shop, khóa + tooltip). */
  minLevel: number;
  paymentMode: AvatarFramePaymentMode;
  /** Giá GTU (null nếu chỉ kim cương). */
  priceCoins: number | null;
  /** Giá kim cương (null nếu chỉ GTU). */
  priceDiamonds: number | null;
}

export const AVATAR_FRAMES_CATALOG: AvatarFrameDefinition[] = [
  { id: 'af_01', name: 'Viền tối giản', description: 'Viền trắng tinh, phong cách tối giản.', tier: 1, minLevel: 1, paymentMode: 'coins', priceCoins: 120, priceDiamonds: null },
  { id: 'af_02', name: 'Sương nhạt', description: 'Viền xám mờ như sương sớm.', tier: 2, minLevel: 2, paymentMode: 'coins', priceCoins: 200, priceDiamonds: null },
  { id: 'af_03', name: 'Tím khói', description: 'Ánh tím nhẹ quanh ảnh.', tier: 3, minLevel: 3, paymentMode: 'coins', priceCoins: 320, priceDiamonds: null },
  { id: 'af_04', name: 'Xanh ngọc', description: 'Viền ngọc bích thanh mát.', tier: 4, minLevel: 4, paymentMode: 'choice', priceCoins: 380, priceDiamonds: 28 },
  { id: 'af_05', name: 'Hồng phấn', description: 'Gradient hồng pastel.', tier: 5, minLevel: 5, paymentMode: 'choice', priceCoins: 480, priceDiamonds: 35 },
  { id: 'af_06', name: 'Hoàng kim', description: 'Viền vàng đồng cổ điển.', tier: 6, minLevel: 6, paymentMode: 'choice', priceCoins: 620, priceDiamonds: 45 },
  { id: 'af_07', name: 'Lục bảo', description: 'Hai lớp viền xanh lục.', tier: 7, minLevel: 8, paymentMode: 'choice', priceCoins: 780, priceDiamonds: 58 },
  { id: 'af_08', name: 'Tím neon', description: 'Glow tím đậm hơn.', tier: 8, minLevel: 10, paymentMode: 'choice', priceCoins: 950, priceDiamonds: 72 },
  { id: 'af_09', name: 'Băng giá', description: 'Viền băng xanh cyan sáng.', tier: 9, minLevel: 12, paymentMode: 'choice', priceCoins: 1150, priceDiamonds: 88 },
  { id: 'af_10', name: 'Hỏa ấn', description: 'Cam đỏ — năng lượng nhiệt.', tier: 10, minLevel: 14, paymentMode: 'choice', priceCoins: 1380, priceDiamonds: 105 },
  { id: 'af_11', name: 'Ấn sao', description: 'Họa tiết sao & glow.', tier: 11, minLevel: 17, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 140 },
  { id: 'af_12', name: 'Long văn', description: 'Vân sóng chạy quanh viền.', tier: 12, minLevel: 20, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 185 },
  { id: 'af_13', name: 'Lôi kiếm', description: 'Tia sét và viền kim loại.', tier: 13, minLevel: 23, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 240 },
  { id: 'af_14', name: 'Nguyệt ấn', description: 'Ánh trăng và vòng đôi.', tier: 14, minLevel: 26, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 310 },
  { id: 'af_15', name: 'Cổ ấn', description: 'Hoa văn cổ trang tinh xảo.', tier: 15, minLevel: 30, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 400 },
  { id: 'af_16', name: 'Thánh quang', description: 'Hào quang vàng rực.', tier: 16, minLevel: 33, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 520 },
  { id: 'af_17', name: 'Tinh vân', description: 'Nhiều lớp gradient tinh thể.', tier: 17, minLevel: 37, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 680 },
  { id: 'af_18', name: 'Vương giả', description: 'Khung đỉnh — đá quý & bóng đổ.', tier: 18, minLevel: 42, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 880 },
  { id: 'af_19', name: 'Thiên long', description: 'Rồng cuộn — chi tiết tối đa.', tier: 19, minLevel: 47, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 1150 },
  { id: 'af_20', name: 'Cửu thiên', description: 'Khung tối thượng — hiếm & lộng lẫy.', tier: 20, minLevel: 52, paymentMode: 'diamonds', priceCoins: null, priceDiamonds: 1500 },
];

export function getFrameById(id: string): AvatarFrameDefinition | undefined {
  return AVATAR_FRAMES_CATALOG.find((f) => f.id === id);
}
