import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { UserOwnedAvatarFrame } from './entities/user-owned-avatar-frame.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import {
  AvatarFrameDefinition,
  getFrameById,
  AVATAR_FRAMES_CATALOG,
} from './avatar-frames.catalog';

@Injectable()
export class AvatarFramesService {
  constructor(
    @InjectRepository(UserOwnedAvatarFrame)
    private ownedRepository: Repository<UserOwnedAvatarFrame>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private currencyService: UserCurrencyService,
  ) {}

  async getCatalog(userId: string): Promise<{
    frames: Array<
      AvatarFrameDefinition & {
        owned: boolean;
        lockedByLevel: boolean;
        canPurchase: boolean;
      }
    >;
    equippedId: string | null;
    level: number;
    coins: number;
    diamonds: number;
  }> {
    const currency = await this.currencyService.getCurrency(userId);
    const level = currency.level || 1;
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      select: ['equippedAvatarFrameId'],
    });
    const ownedRows = await this.ownedRepository.find({
      where: { userId },
    });
    const ownedSet = new Set(ownedRows.map((r) => r.frameId));

    const frames = AVATAR_FRAMES_CATALOG.map((def) => {
      const owned = ownedSet.has(def.id);
      const lockedByLevel = level < def.minLevel;
      const canPurchase =
        !owned && !lockedByLevel;
      return {
        ...def,
        owned,
        lockedByLevel,
        canPurchase,
      };
    });

    return {
      frames,
      equippedId: user?.equippedAvatarFrameId ?? null,
      level,
      coins: currency.coins ?? 0,
      diamonds: currency.diamonds ?? 0,
    };
  }

  async purchase(
    userId: string,
    frameId: string,
    currency: 'coins' | 'diamonds' | undefined,
  ): Promise<{
    frame: AvatarFrameDefinition;
    paidWith: 'coins' | 'diamonds';
    amount: number;
    coins: number;
    diamonds: number;
  }> {
    const def = getFrameById(frameId);
    if (!def) {
      throw new NotFoundException('Không có khung này');
    }

    const cur = await this.currencyService.getCurrency(userId);
    const level = cur.level || 1;
    if (level < def.minLevel) {
      throw new BadRequestException(
        `Cần đạt cấp ${def.minLevel} để mua khung này (hiện tại cấp ${level}).`,
      );
    }

    const existing = await this.ownedRepository.findOne({
      where: { userId, frameId },
    });
    if (existing) {
      throw new BadRequestException('Bạn đã sở hữu khung này');
    }

    let paidWith: 'coins' | 'diamonds';
    let amount: number;

    if (def.paymentMode === 'coins') {
      if (currency && currency !== 'coins') {
        throw new BadRequestException('Khung này chỉ mua bằng GTU coin');
      }
      if (def.priceCoins == null) {
        throw new BadRequestException('Cấu hình giá GTU không hợp lệ');
      }
      paidWith = 'coins';
      amount = def.priceCoins;
      const ok = await this.currencyService.hasEnoughCoins(userId, amount);
      if (!ok) {
        throw new BadRequestException(
          `Không đủ GTU. Cần ${amount} GTU; bạn có ${cur.coins ?? 0}.`,
        );
      }
      await this.currencyService.deductCoins(userId, amount);
    } else if (def.paymentMode === 'diamonds') {
      if (currency && currency !== 'diamonds') {
        throw new BadRequestException('Khung này chỉ mua bằng kim cương');
      }
      if (def.priceDiamonds == null) {
        throw new BadRequestException('Cấu hình giá kim cương không hợp lệ');
      }
      paidWith = 'diamonds';
      amount = def.priceDiamonds;
      const ok = await this.currencyService.hasEnoughDiamonds(userId, amount);
      if (!ok) {
        throw new BadRequestException(
          `Không đủ kim cương. Cần ${amount} 💎; bạn có ${cur.diamonds ?? 0}.`,
        );
      }
      await this.currencyService.deductDiamonds(userId, amount);
    } else {
      // choice
      if (!currency || (currency !== 'coins' && currency !== 'diamonds')) {
        throw new BadRequestException(
          'Chọn loại tiền trước khi mua: coins (GTU) hoặc diamonds (kim cương).',
        );
      }
      if (currency === 'coins') {
        if (def.priceCoins == null) {
          throw new BadRequestException('Khung này không bán bằng GTU');
        }
        paidWith = 'coins';
        amount = def.priceCoins;
        const ok = await this.currencyService.hasEnoughCoins(userId, amount);
        if (!ok) {
          throw new BadRequestException(
            `Không đủ GTU. Cần ${amount} GTU; bạn có ${cur.coins ?? 0}.`,
          );
        }
        await this.currencyService.deductCoins(userId, amount);
      } else {
        if (def.priceDiamonds == null) {
          throw new BadRequestException('Khung này không bán bằng kim cương');
        }
        paidWith = 'diamonds';
        amount = def.priceDiamonds;
        const ok = await this.currencyService.hasEnoughDiamonds(userId, amount);
        if (!ok) {
          throw new BadRequestException(
            `Không đủ kim cương. Cần ${amount} 💎; bạn có ${cur.diamonds ?? 0}.`,
          );
        }
        await this.currencyService.deductDiamonds(userId, amount);
      }
    }

    await this.ownedRepository.save(
      this.ownedRepository.create({ userId, frameId }),
    );

    const updated = await this.currencyService.getCurrency(userId);
    return {
      frame: def,
      paidWith,
      amount,
      coins: updated.coins ?? 0,
      diamonds: updated.diamonds ?? 0,
    };
  }

  async equip(
    userId: string,
    frameId: string | null | undefined,
  ): Promise<{ equippedAvatarFrameId: string | null }> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    if (frameId == null || frameId === '') {
      user.equippedAvatarFrameId = null;
      await this.usersRepository.save(user);
      return { equippedAvatarFrameId: null };
    }

    const def = getFrameById(frameId);
    if (!def) {
      throw new BadRequestException('Mã khung không hợp lệ');
    }

    const owned = await this.ownedRepository.findOne({
      where: { userId, frameId },
    });
    if (!owned) {
      throw new BadRequestException('Bạn chưa sở hữu khung này');
    }

    user.equippedAvatarFrameId = frameId;
    await this.usersRepository.save(user);
    return { equippedAvatarFrameId: frameId };
  }
}
