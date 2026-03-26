import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThanOrEqual, Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(UserCurrency)
    private currencyRepository: Repository<UserCurrency>,
    @InjectRepository(UserProgress)
    private progressRepository: Repository<UserProgress>,
  ) {}

  /**
   * Snapshot năng lực (MVP): mới tính chỉ số "memory", metric khác giữ 0.
   * Công thức memory dùng dữ liệu có sẵn để test tăng/giảm theo hoạt động học:
   * - completedNodes (all-time): 55%
   * - currentStreak: 30%
   * - completions 7 ngày gần nhất: 15%
   */
  async getCompetencies(userId: string) {
    const [currency, completedNodes, completedLast7Days] = await Promise.all([
      this.currencyRepository.findOne({
        where: { userId },
        select: ['currentStreak'],
      }),
      this.progressRepository.count({
        where: { userId, isCompleted: true },
      }),
      this.progressRepository.count({
        where: {
          userId,
          isCompleted: true,
          completedAt: MoreThanOrEqual(
            new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
          ),
        },
      }),
    ]);

    const streak = currency?.currentStreak ?? 0;
    const completedNorm = Math.min(1, completedNodes / 80); // 80 bài -> full
    const streakNorm = Math.min(1, streak / 14); // 14 ngày -> full
    const weeklyNorm = Math.min(1, completedLast7Days / 12); // 12 bài/tuần -> full

    const memoryScore = Math.round(
      (completedNorm * 0.55 + streakNorm * 0.30 + weeklyNorm * 0.15) * 100,
    );

    return {
      learningMetrics: [
        { key: 'memory', value: memoryScore },
        { key: 'logical_thinking', value: 0 },
        { key: 'processing_speed', value: 0 },
        { key: 'practical_application', value: 0 },
        { key: 'metacognition', value: 0 },
        { key: 'learning_persistence', value: 0 },
        { key: 'knowledge_absorption', value: 0 },
      ],
      humanMetrics: [
        { key: 'systems_thinking', value: 0 },
        { key: 'creativity', value: 0 },
        { key: 'communication', value: 0 },
        { key: 'self_leadership', value: 0 },
        { key: 'discipline', value: 0 },
        { key: 'growth_mindset', value: 0 },
        { key: 'critical_thinking', value: 0 },
        { key: 'collaboration', value: 0 },
      ],
      formulaInfo: {
        memory: {
          completedNodes,
          currentStreak: streak,
          completedLast7Days,
        },
      },
    };
  }

  async create(email: string, password: string, fullName?: string): Promise<User> {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = this.usersRepository.create({
      email,
      password: hashedPassword,
      fullName,
    });
    return this.usersRepository.save(user);
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email } });
  }

  async findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  /** Hồ sơ công khai (bảng xếp hạng / bạn bè) — không trả email, password. */
  async getPublicProfile(userId: string) {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      // NOTE: must include avatarUrl, otherwise TypeORM returns it as undefined/null
      select: ['id', 'fullName', 'avatarUrl', 'totalXP', 'role', 'createdAt'],
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const currency = await this.currencyRepository.findOne({
      where: { userId },
      select: [
        'coins',
        'diamonds',
        'level',
        'currentStreak',
        'maxStreak',
        'weeklyXp',
      ],
    });
    return {
      id: user.id,
      fullName: user.fullName || 'Anonymous',
      avatarUrl: user.avatarUrl ?? null,
      totalXP: user.totalXP ?? 0,
      role: user.role,
      memberSince: user.createdAt?.toISOString?.() ?? null,
      coins: currency?.coins ?? 0,
      diamonds: currency?.diamonds ?? 0,
      level: currency?.level ?? 1,
      currentStreak: currency?.currentStreak ?? 0,
      maxStreak: currency?.maxStreak ?? 0,
      weeklyXp: currency?.weeklyXp ?? 0,
    };
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.password);
  }

  async updateOnboardingData(userId: string, data: Record<string, any>): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    user.onboardingData = data;
    return this.usersRepository.save(user);
  }

  async updatePlacementTest(
    userId: string,
    score: number,
    level: string,
  ): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    user.placementTestScore = score;
    user.placementTestLevel = level;
    return this.usersRepository.save(user);
  }

  async updateStreak(userId: string, streak: number): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    user.currentStreak = streak;
    return this.usersRepository.save(user);
  }

  async addXP(userId: string, xp: number): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    user.totalXP += xp;
    return this.usersRepository.save(user);
  }

  async updateProfile(
    userId: string,
    data: { fullName?: string; phone?: string; avatarUrl?: string },
  ): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    if (data.fullName !== undefined) {
      const t = data.fullName.trim();
      if (t.length === 0) {
        throw new BadRequestException('fullName cannot be empty');
      }
      if (t.length > 120) {
        throw new BadRequestException('fullName too long');
      }
      user.fullName = t;
    }
    if (data.phone !== undefined) {
      const p = data.phone.trim();
      user.phone = p.length > 0 ? p : null;
    }
    if (data.avatarUrl !== undefined) {
      const v = data.avatarUrl.trim();
      user.avatarUrl = v.length > 0 ? v : null;
    }
    return this.usersRepository.save(user);
  }

  async findOrCreateGoogleUser(email: string, fullName?: string): Promise<User> {
    let user = await this.findByEmail(email);
    if (user) {
      if (user.authProvider !== 'google') {
        user.authProvider = 'google';
        user = await this.usersRepository.save(user);
      }
      return user;
    }
    const randomPass = await bcrypt.hash(Math.random().toString(36), 10);
    const newUser = this.usersRepository.create({
      email,
      password: randomPass,
      fullName: fullName || email.split('@')[0],
      authProvider: 'google',
    });
    return this.usersRepository.save(newUser);
  }

  async setResetToken(userId: string, token: string, expires: Date): Promise<void> {
    await this.usersRepository.update(userId, {
      resetPasswordToken: token,
      resetPasswordExpires: expires,
    });
  }

  async findByResetToken(token: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { resetPasswordToken: token } });
  }

  async updatePassword(userId: string, hashedPassword: string): Promise<void> {
    await this.usersRepository.update(userId, {
      password: hashedPassword,
      resetPasswordToken: null,
      resetPasswordExpires: null,
    });
  }

  async switchRole(
    userId: string,
    targetRole: 'user' | 'contributor',
  ): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    // Admin cannot switch to lower roles via this endpoint
    if (user.role === 'admin') {
      throw new Error('Admin role cannot be changed');
    }
    // Only allow switching between user and contributor
    if (targetRole !== 'user' && targetRole !== 'contributor') {
      throw new Error('Invalid target role');
    }
    user.role = targetRole;
    return this.usersRepository.save(user);
  }
}

