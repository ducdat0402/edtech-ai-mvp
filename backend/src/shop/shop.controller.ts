import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { ShopService } from './shop.service';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('shop')
@UseGuards(JwtAuthGuard)
export class ShopController {
  constructor(
    private readonly shopService: ShopService,
    private readonly currencyService: UserCurrencyService,
  ) {}

  @Get('items')
  async getShopItems(@Request() req) {
    const items = this.shopService.getShopItems();
    const currency = await this.currencyService.getCurrency(req.user.id);

    return {
      coins: currency.coins,
      items: items.map((item) => ({
        ...item,
        canAfford: currency.coins >= item.price,
      })),
    };
  }

  @Get('inventory')
  async getInventory(@Request() req) {
    const inventory = await this.shopService.getInventory(req.user.id);
    const hasXPBoost = await this.shopService.hasActiveXPBoost(req.user.id);

    return {
      inventory,
      activeEffects: {
        xpBoost: hasXPBoost,
      },
    };
  }

  @Post('purchase')
  async purchase(
    @Request() req,
    @Body() body: { itemId: string; quantity?: number },
  ) {
    const { itemId, quantity } = body;
    if (!itemId) {
      throw new Error('itemId is required');
    }
    return this.shopService.purchase(req.user.id, itemId, quantity || 1);
  }

  @Post('use')
  async useItem(
    @Request() req,
    @Body() body: { itemId: string },
  ) {
    if (!body.itemId) {
      throw new Error('itemId is required');
    }
    return this.shopService.useItem(req.user.id, body.itemId);
  }
}
