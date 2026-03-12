import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ShopService } from './shop.service';
import { ShopController } from './shop.controller';
import { UserItem } from './entities/user-item.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserItem]),
    UserCurrencyModule,
  ],
  controllers: [ShopController],
  providers: [ShopService],
  exports: [ShopService],
})
export class ShopModule {}
