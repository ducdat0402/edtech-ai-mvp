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
}

