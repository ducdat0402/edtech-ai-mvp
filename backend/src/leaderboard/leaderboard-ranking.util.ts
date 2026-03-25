/**
 * Ordinal ranking (hạng 1,2,3,4 — không gom đồng hạng).
 * Đồng điểm: ưu tiên updatedAt nhỏ hơn (đạt mốc trước), rồi id ổn định.
 */

export const GLOBAL_STRICTLY_AHEAD_WHERE = `(
  user.totalXP > :xp
  OR (user.totalXP = :xp AND user.updatedAt < :ua)
  OR (user.totalXP = :xp AND user.updatedAt = :ua AND user.id < :uid)
)`;

export const WEEKLY_CURRENCY_STRICTLY_AHEAD_WHERE = `(
  c.weeklyXp > :wxp
  OR (c.weeklyXp = :wxp AND c.updatedAt < :ua)
  OR (c.weeklyXp = :wxp AND c.updatedAt = :ua AND c.userId < :uid)
)`;

export function bindGlobalStrictlyAhead(user: {
  id: string;
  totalXP: number;
  updatedAt: Date;
}) {
  return {
    xp: user.totalXP,
    ua: user.updatedAt,
    uid: user.id,
  };
}

export function bindWeeklyCurrencyStrictlyAhead(row: {
  userId: string;
  weeklyXp: number;
  updatedAt: Date;
}) {
  return {
    wxp: row.weeklyXp,
    ua: row.updatedAt,
    uid: row.userId,
  };
}
