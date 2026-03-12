import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
import { UserItem } from './entities/user-item.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';

export interface ShopItem {
  id: string;
  name: string;
  description: string;
  price: number;
  icon: string;
  category: 'boost' | 'protection' | 'consumable' | 'cosmetic' | 'mystery';
  effectType: 'xp_boost' | 'streak_shield' | 'hint_token' | 'mystery_box' | 'cosmetic';
  effectDuration?: number; // minutes, null = permanent/consumable
  maxStack: number;
}

@Injectable()
export class ShopService {
  private readonly shopItems: ShopItem[] = [
    {
      id: 'xp_boost_2x',
      name: 'Boost XP x2',
      description: 'Nhân đôi XP nhận được trong 1 giờ',
      price: 200,
      icon: 'auto_awesome',
      category: 'boost',
      effectType: 'xp_boost',
      effectDuration: 60,
      maxStack: 10,
    },
    {
      id: 'streak_shield',
      name: 'Streak Shield',
      description: 'Bảo vệ streak khi lỡ quên 1 ngày',
      price: 300,
      icon: 'shield',
      category: 'protection',
      effectType: 'streak_shield',
      effectDuration: null,
      maxStack: 5,
    },
    {
      id: 'hint_token',
      name: 'Hint Token',
      description: 'Gợi ý đáp án khi làm quiz',
      price: 100,
      icon: 'tips_and_updates',
      category: 'consumable',
      effectType: 'hint_token',
      effectDuration: null,
      maxStack: 20,
    },
    {
      id: 'mystery_box',
      name: 'Hộp quà may mắn',
      description: 'Nhận ngẫu nhiên XP, Coins hoặc vật phẩm',
      price: 150,
      icon: 'card_giftcard',
      category: 'mystery',
      effectType: 'mystery_box',
      effectDuration: null,
      maxStack: 99,
    },
  ];

  constructor(
    @InjectRepository(UserItem)
    private userItemRepository: Repository<UserItem>,
    private currencyService: UserCurrencyService,
  ) {}

  getShopItems(): ShopItem[] {
    return this.shopItems;
  }

  getShopItem(itemId: string): ShopItem | undefined {
    return this.shopItems.find((i) => i.id === itemId);
  }

  async purchase(userId: string, itemId: string, quantity: number = 1): Promise<{
    item: ShopItem;
    totalCost: number;
    newBalance: number;
    inventory: UserItem;
  }> {
    const shopItem = this.getShopItem(itemId);
    if (!shopItem) {
      throw new BadRequestException('Vật phẩm không tồn tại');
    }

    if (quantity < 1 || quantity > 10) {
      throw new BadRequestException('Số lượng phải từ 1 đến 10');
    }

    const totalCost = shopItem.price * quantity;

    const currentOwned = await this.getItemCount(userId, itemId);
    if (currentOwned + quantity > shopItem.maxStack) {
      throw new BadRequestException(
        `Bạn chỉ có thể sở hữu tối đa ${shopItem.maxStack} ${shopItem.name}. Hiện có: ${currentOwned}`,
      );
    }

    const hasEnough = await this.currencyService.hasEnoughCoins(userId, totalCost);
    if (!hasEnough) {
      const currency = await this.currencyService.getCurrency(userId);
      throw new BadRequestException(
        `Không đủ Coins. Cần ${totalCost} 🪙, bạn có ${currency.coins} 🪙.`,
      );
    }

    const updatedCurrency = await this.currencyService.deductCoins(userId, totalCost);

    let existingItem = await this.userItemRepository.findOne({
      where: { userId, itemId },
    });

    if (existingItem) {
      existingItem.quantity += quantity;
      existingItem = await this.userItemRepository.save(existingItem);
    } else {
      existingItem = this.userItemRepository.create({
        userId,
        itemId,
        quantity,
      });
      existingItem = await this.userItemRepository.save(existingItem);
    }

    return {
      item: shopItem,
      totalCost,
      newBalance: updatedCurrency.coins,
      inventory: existingItem,
    };
  }

  async getInventory(userId: string): Promise<Array<{
    item: ShopItem;
    quantity: number;
    isActive: boolean;
    expiresAt: Date | null;
  }>> {
    const userItems = await this.userItemRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });

    return userItems
      .map((ui) => {
        const shopItem = this.getShopItem(ui.itemId);
        if (!shopItem) return null;
        return {
          item: shopItem,
          quantity: ui.quantity,
          isActive: ui.isActive,
          expiresAt: ui.expiresAt,
        };
      })
      .filter(Boolean);
  }

  async useItem(userId: string, itemId: string): Promise<{
    success: boolean;
    message: string;
    reward?: { xp?: number; coins?: number; item?: string };
    expiresAt?: Date;
  }> {
    const shopItem = this.getShopItem(itemId);
    if (!shopItem) {
      throw new BadRequestException('Vật phẩm không tồn tại');
    }

    const userItem = await this.userItemRepository.findOne({
      where: { userId, itemId },
    });

    if (!userItem || userItem.quantity <= 0) {
      throw new BadRequestException('Bạn không có vật phẩm này');
    }

    if (shopItem.effectType === 'xp_boost') {
      const existing = await this.userItemRepository.findOne({
        where: { userId, itemId, isActive: true, expiresAt: MoreThan(new Date()) },
      });
      if (existing) {
        throw new BadRequestException('Boost XP đang hoạt động. Hãy chờ hết hiệu lực.');
      }

      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + (shopItem.effectDuration || 60));

      userItem.quantity -= 1;
      userItem.isActive = true;
      userItem.activatedAt = new Date();
      userItem.expiresAt = expiresAt;
      await this.userItemRepository.save(userItem);

      return {
        success: true,
        message: `Boost XP x2 đã kích hoạt! Hiệu lực ${shopItem.effectDuration} phút.`,
        expiresAt,
      };
    }

    if (shopItem.effectType === 'streak_shield') {
      userItem.quantity -= 1;
      userItem.isActive = true;
      userItem.activatedAt = new Date();
      await this.userItemRepository.save(userItem);

      return {
        success: true,
        message: 'Streak Shield đã kích hoạt! Streak của bạn sẽ được bảo vệ nếu lỡ quên 1 ngày.',
      };
    }

    if (shopItem.effectType === 'hint_token') {
      userItem.quantity -= 1;
      await this.userItemRepository.save(userItem);

      return {
        success: true,
        message: 'Đã sử dụng 1 Hint Token.',
      };
    }

    if (shopItem.effectType === 'mystery_box') {
      userItem.quantity -= 1;
      await this.userItemRepository.save(userItem);

      const reward = this.generateMysteryReward();

      if (reward.xp && reward.xp > 0) {
        await this.currencyService.addXP(userId, reward.xp);
      }
      if (reward.coins && reward.coins > 0) {
        await this.currencyService.addCoins(userId, reward.coins);
      }

      return {
        success: true,
        message: `Bạn nhận được: ${reward.description}`,
        reward: { xp: reward.xp, coins: reward.coins, item: reward.item },
      };
    }

    throw new BadRequestException('Vật phẩm này chưa thể sử dụng');
  }

  async hasActiveXPBoost(userId: string): Promise<boolean> {
    const active = await this.userItemRepository.findOne({
      where: {
        userId,
        itemId: 'xp_boost_2x',
        isActive: true,
        expiresAt: MoreThan(new Date()),
      },
    });
    return !!active;
  }

  async hasStreakShield(userId: string): Promise<boolean> {
    const shield = await this.userItemRepository.findOne({
      where: { userId, itemId: 'streak_shield', isActive: true },
    });
    return !!shield && shield.quantity >= 0;
  }

  async consumeStreakShield(userId: string): Promise<boolean> {
    const shield = await this.userItemRepository.findOne({
      where: { userId, itemId: 'streak_shield', isActive: true },
    });
    if (!shield) return false;

    shield.isActive = false;
    await this.userItemRepository.save(shield);
    return true;
  }

  async getHintTokenCount(userId: string): Promise<number> {
    return this.getItemCount(userId, 'hint_token');
  }

  private async getItemCount(userId: string, itemId: string): Promise<number> {
    const item = await this.userItemRepository.findOne({
      where: { userId, itemId },
    });
    return item?.quantity ?? 0;
  }

  private generateMysteryReward(): {
    xp: number;
    coins: number;
    item: string | null;
    description: string;
  } {
    const roll = Math.random();

    if (roll < 0.35) {
      const xp = Math.floor(Math.random() * 50) + 20;
      return { xp, coins: 0, item: null, description: `${xp} XP` };
    }
    if (roll < 0.65) {
      const coins = Math.floor(Math.random() * 80) + 30;
      return { xp: 0, coins, item: null, description: `${coins} Coins` };
    }
    if (roll < 0.85) {
      const xp = Math.floor(Math.random() * 30) + 10;
      const coins = Math.floor(Math.random() * 40) + 15;
      return { xp, coins, item: null, description: `${xp} XP + ${coins} Coins` };
    }
    const xp = Math.floor(Math.random() * 100) + 50;
    const coins = Math.floor(Math.random() * 100) + 50;
    return { xp, coins, item: null, description: `🎉 Jackpot! ${xp} XP + ${coins} Coins` };
  }
}
