import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

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
    data: { fullName?: string; phone?: string },
  ): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    if (data.fullName) {
      user.fullName = data.fullName;
    }
    if (data.phone) {
      user.phone = data.phone;
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

