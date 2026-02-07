// Leaderboard không cần entity riêng, sẽ query trực tiếp từ User và UserCurrency
// File này chỉ để documentation

export interface LeaderboardEntry {
  rank: number;
  userId: string;
  fullName: string;
  email: string;
  totalXP: number;
  coins: number;
  currentStreak: number;
  avatar?: string;
}

export interface LeaderboardResponse {
  entries: LeaderboardEntry[];
  userRank?: number;
  totalUsers: number;
  page: number;
  limit: number;
}

