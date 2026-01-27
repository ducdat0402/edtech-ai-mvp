import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UnlockTransaction } from './entities/unlock-transaction.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { SubjectsService } from '../subjects/subjects.service';

@Injectable()
export class UnlockTransactionsService {
  constructor(
    @InjectRepository(UnlockTransaction)
    private transactionRepository: Repository<UnlockTransaction>,
    private currencyService: UserCurrencyService,
    private subjectsService: SubjectsService,
  ) {}

  async unlockScholar(
    userId: string,
    subjectId: string,
    paymentAmount?: number,
  ): Promise<UnlockTransaction> {
    const subject = await this.subjectsService.findById(subjectId);
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    if (subject.track !== 'scholar') {
      throw new BadRequestException('Only Scholar subjects can be unlocked');
    }

    const currency = await this.currencyService.getCurrency(userId);
    const requiredCoins = subject.unlockConditions?.minCoin || 20;

    if (currency.coins < requiredCoins) {
      throw new BadRequestException(
        `Cần tối thiểu ${requiredCoins} coin. Bạn còn thiếu ${
          requiredCoins - currency.coins
        } coin.`,
      );
    }

    // Tính toán: 20% coin + 80% payment
    const totalPrice = subject.price || 100000; // 100k VND default
    const coinValue = totalPrice * 0.2; // 20k
    const paymentRequired = totalPrice * 0.8; // 80k

    if (paymentAmount && paymentAmount < paymentRequired) {
      throw new BadRequestException(
        `Cần thanh toán tối thiểu ${paymentRequired} VND`,
      );
    }

    // Trừ coin
    await this.currencyService.deductCoins(userId, requiredCoins);

    // Tạo transaction
    const transaction = this.transactionRepository.create({
      userId,
      subjectId,
      coinsUsed: requiredCoins,
      paymentAmount: paymentAmount || paymentRequired,
      unlockType: paymentAmount ? 'coin_plus_payment' : 'coin_only',
      status: paymentAmount ? 'pending' : 'completed', // Nếu có payment thì pending, chờ verify
    });

    return this.transactionRepository.save(transaction);
  }

  async getUserTransactions(userId: string): Promise<UnlockTransaction[]> {
    return this.transactionRepository.find({
      where: { userId },
      relations: ['subject'],
      order: { createdAt: 'DESC' },
    });
  }

  async completeTransaction(transactionId: string): Promise<UnlockTransaction> {
    const transaction = await this.transactionRepository.findOne({
      where: { id: transactionId },
    });

    if (!transaction) {
      throw new NotFoundException('Transaction not found');
    }

    transaction.status = 'completed';
    return this.transactionRepository.save(transaction);
  }
}

