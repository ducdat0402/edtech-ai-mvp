import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan, DataSource } from 'typeorm';
import { Payment, PaymentStatus } from './entities/payment.entity';
import { UserPremium } from './entities/user-premium.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { RewardTransaction, RewardSource } from '../user-currency/entities/reward-transaction.entity';
import { ConfigService } from '@nestjs/config';

// SePay webhook payload interface
interface SepayWebhookPayload {
  id: number;
  gateway: string;
  transactionDate: string;
  accountNumber: string;
  subAccount: string | null;
  code: string | null;
  content: string;
  transferType: string;
  description: string;
  transferAmount: number;
  referenceCode: string;
  accumulated: number;
}

// Bank info for QR generation
export interface BankInfo {
  bankName: string;
  bankCode: string;
  accountNumber: string;
  accountName: string;
}

// Diamond payment packages
export interface PaymentPackage {
  id: string;
  name: string;
  price: number;
  diamonds: number;       // Base diamonds
  bonusDiamonds: number;  // Bonus diamonds
  totalDiamonds: number;  // diamonds + bonusDiamonds
  bonusPercent: number;    // Bonus percentage (0, 20, 40, 50)
  pricePerDiamond: number; // Price per diamond (VND)
  discount: string;        // Discount label ("", "-13%", "-25%", "-30%")
  description: string;
  badge: string;           // "", "Phổ biến nhất", "Tiết kiệm", "Best Deal"
  isPopular: boolean;
}

@Injectable()
export class PaymentService {
  private readonly bankInfo: BankInfo = {
    bankName: 'MB Bank',
    bankCode: 'MB',
    accountNumber: '0983425129',
    accountName: 'LE DUC DAT',
  };

  private readonly packages: PaymentPackage[] = [
    {
      id: 'diamond_starter',
      name: 'Starter',
      price: 19000,
      diamonds: 200,
      bonusDiamonds: 0,
      totalDiamonds: 200,
      bonusPercent: 0,
      pricePerDiamond: 95,
      discount: '',
      description: 'Bắt đầu hành trình học tập',
      badge: '',
      isPopular: false,
    },
    {
      id: 'diamond_popular',
      name: 'Popular',
      price: 79000,
      diamonds: 800,
      bonusDiamonds: 200,
      totalDiamonds: 1000,
      bonusPercent: 25,
      pricePerDiamond: 79,
      discount: '-17%',
      description: 'Gói được chọn nhiều nhất',
      badge: 'Phổ biến nhất',
      isPopular: true,
    },
    {
      id: 'diamond_pro',
      name: 'Pro',
      price: 199000,
      diamonds: 1500,
      bonusDiamonds: 1000,
      totalDiamonds: 2500,
      bonusPercent: 67,
      pricePerDiamond: 80,
      discount: '-16%',
      description: 'Best Value - Giá trị tốt nhất',
      badge: 'Best Value',
      isPopular: false,
    },
    {
      id: 'diamond_premium',
      name: 'Premium',
      price: 399000,
      diamonds: 3000,
      bonusDiamonds: 3000,
      totalDiamonds: 6000,
      bonusPercent: 100,
      pricePerDiamond: 67,
      discount: '-29%',
      description: 'Siêu tiết kiệm cho người học nghiêm túc',
      badge: 'Siêu tiết kiệm',
      isPopular: false,
    },
  ];

  constructor(
    @InjectRepository(Payment)
    private paymentRepository: Repository<Payment>,
    @InjectRepository(UserPremium)
    private userPremiumRepository: Repository<UserPremium>,
    private userCurrencyService: UserCurrencyService,
    private configService: ConfigService,
    private dataSource: DataSource,
  ) {}

  // Get all available packages
  getPackages(): PaymentPackage[] {
    return this.packages;
  }

  // Get bank info for display
  getBankInfo(): BankInfo {
    return this.bankInfo;
  }

  // Generate unique payment code
  private generatePaymentCode(): string {
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `ED${timestamp}${random}`;
  }

  /**
   * Create a new payment order (ACID transaction).
   *
   * Uses a transaction to atomically:
   * 1. Cancel any existing pending payment for this user
   * 2. Create the new payment record
   *
   * This prevents race conditions where a user rapidly creates multiple payments
   * and ends up with more than one 'pending' payment.
   */
  async createPayment(
    userId: string,
    packageId: string,
  ): Promise<{
    payment: Payment;
    bankInfo: BankInfo;
    qrContent: string;
    package: PaymentPackage;
  }> {
    const pkg = this.packages.find((p) => p.id === packageId);
    if (!pkg) {
      throw new BadRequestException('Gói thanh toán không tồn tại');
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Find and cancel existing pending payment (within transaction)
      const existingPending = await queryRunner.manager.findOne(Payment, {
        where: { userId, status: 'pending' as PaymentStatus },
        lock: { mode: 'pessimistic_write' },
      });

      if (existingPending) {
        existingPending.status = 'cancelled';
        await queryRunner.manager.save(existingPending);
      }

      // 2. Create new payment (within same transaction)
      const paymentCode = this.generatePaymentCode();
      const expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + 24); // 24 hours to pay

      const payment = queryRunner.manager.create(Payment, {
        userId,
        paymentCode,
        packageName: pkg.name,
        amount: pkg.price,
        description: `${pkg.totalDiamonds} kim cương (${pkg.diamonds}+${pkg.bonusDiamonds} bonus)`,
        diamondAmount: pkg.totalDiamonds,
        durationDays: 0,
        status: 'pending',
        expiresAt,
      });

      const savedPayment = await queryRunner.manager.save(payment);

      // 3. Commit: both cancel + create succeed together
      await queryRunner.commitTransaction();

      // Generate QR content (VietQR format) - outside transaction, no DB writes
      const qrContent = this.generateVietQRContent(pkg.price, paymentCode);

      return {
        payment: savedPayment,
        bankInfo: this.bankInfo,
        qrContent,
        package: pkg,
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  // Generate VietQR content string
  private generateVietQRContent(amount: number, content: string): string {
    const bankCode = 'MB';
    const accountNumber = this.bankInfo.accountNumber;
    return `https://img.vietqr.io/image/${bankCode}-${accountNumber}-compact2.png?amount=${amount}&addInfo=${encodeURIComponent(content)}&accountName=${encodeURIComponent(this.bankInfo.accountName)}`;
  }

  // Get payment by ID
  async getPayment(paymentId: string, userId: string): Promise<Payment> {
    const payment = await this.paymentRepository.findOne({
      where: { id: paymentId, userId },
    });

    if (!payment) {
      throw new NotFoundException('Không tìm thấy đơn thanh toán');
    }

    return payment;
  }

  // Get user's payment history
  async getPaymentHistory(userId: string): Promise<Payment[]> {
    return this.paymentRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  // Get user's diamond balance (from currency system)
  async getDiamondBalance(userId: string): Promise<{
    diamonds: number;
    level: number;
    xp: number;
  }> {
    const currency = await this.userCurrencyService.getOrCreate(userId);
    return {
      diamonds: currency.coins,
      level: currency.level,
      xp: currency.xp,
    };
  }

  /**
   * Handle SePay webhook with full ACID guarantees:
   *
   * - Atomicity: All operations (update payment + add coins + log reward) are in ONE transaction.
   *   If any step fails, everything rolls back.
   *
   * - Consistency: Payment status and coin balance are always consistent.
   *   A payment can only transition from 'pending' → 'paid' once.
   *
   * - Isolation: PESSIMISTIC_WRITE lock on the payment row prevents duplicate processing
   *   even if SePay sends the webhook multiple times concurrently.
   *
   * - Durability: PostgreSQL commits the transaction to WAL before returning.
   *
   * Additional safeguard: transactionId has a UNIQUE constraint in the database,
   * so even if the lock somehow fails, duplicate inserts are rejected.
   */
  async handleSepayWebhook(
    payload: SepayWebhookPayload,
    apiKey: string,
  ): Promise<{ success: boolean; message: string }> {
    // === Pre-validation (outside transaction - no DB writes) ===

    // Verify API key
    const expectedApiKey = this.configService.get<string>('SEPAY_WEBHOOK_API_KEY');
    if (apiKey !== `Apikey ${expectedApiKey}`) {
      console.log('❌ Invalid SePay API key');
      return { success: false, message: 'Invalid API key' };
    }

    console.log('📥 SePay Webhook received:', JSON.stringify(payload, null, 2));

    // Extract payment code from content
    const content = payload.content || '';
    const paymentCodeMatch = content.match(/ED[A-Z0-9]+/i);

    if (!paymentCodeMatch) {
      console.log('⚠️ No payment code found in content:', content);
      return { success: false, message: 'No payment code found' };
    }

    const paymentCode = paymentCodeMatch[0].toUpperCase();
    const sepayTransactionId = payload.id.toString();
    console.log('🔍 Looking for payment code:', paymentCode);

    // === Idempotency check: has this SePay transaction already been processed? ===
    const alreadyProcessed = await this.paymentRepository.findOne({
      where: { transactionId: sepayTransactionId },
    });
    if (alreadyProcessed) {
      console.log('ℹ️ Webhook already processed (idempotency), transactionId:', sepayTransactionId);
      return { success: true, message: 'Already processed' };
    }

    // === ACID Transaction: all-or-nothing ===
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction('SERIALIZABLE');

    try {
      // 1. Find and LOCK the payment row (PESSIMISTIC_WRITE prevents concurrent processing)
      const payment = await queryRunner.manager.findOne(Payment, {
        where: {
          paymentCode,
          status: 'pending' as PaymentStatus,
        },
        lock: { mode: 'pessimistic_write' },
      });

      if (!payment) {
        await queryRunner.rollbackTransaction();
        console.log('⚠️ Payment not found or not pending:', paymentCode);
        return { success: false, message: 'Payment not found or already processed' };
      }

      // 2. Verify transfer amount
      if (payload.transferAmount < payment.amount) {
        await queryRunner.rollbackTransaction();
        console.log(`⚠️ Amount mismatch: received ${payload.transferAmount}, expected ${payment.amount}`);
        return { success: false, message: 'Amount mismatch' };
      }

      // 3. Update payment status (within transaction)
      payment.status = 'paid';
      payment.transactionId = sepayTransactionId;
      payment.bankReference = payload.referenceCode;
      payment.paidAt = new Date();
      await queryRunner.manager.save(payment);

      console.log('✅ Payment marked as paid:', payment.id);

      // 4. Add diamonds using atomic increment (within same transaction)
      const diamondAmount = payment.diamondAmount || 0;
      if (diamondAmount > 0) {
        // Ensure user currency exists
        const existingCurrency = await queryRunner.manager.findOne(UserCurrency, {
          where: { userId: payment.userId },
        });

        if (!existingCurrency) {
          // Create user currency if not exists
          const newCurrency = queryRunner.manager.create(UserCurrency, {
            userId: payment.userId,
            coins: diamondAmount,
            xp: 0,
            level: 1,
            currentStreak: 0,
            shards: {},
          });
          await queryRunner.manager.save(newCurrency);
        } else {
          // Atomic increment within transaction
          await queryRunner.manager
            .createQueryBuilder()
            .update(UserCurrency)
            .set({ coins: () => `coins + ${Math.floor(diamondAmount)}` })
            .where('userId = :userId', { userId: payment.userId })
            .execute();
        }

        // 5. Log reward transaction (within same transaction)
        const rewardLog = queryRunner.manager.create(RewardTransaction, {
          userId: payment.userId,
          source: RewardSource.PURCHASE,
          sourceId: payment.id,
          sourceName: `Mua ${diamondAmount} kim cương - Gói ${payment.packageName}`,
          xp: 0,
          coins: diamondAmount,
          shards: {},
        });
        await queryRunner.manager.save(rewardLog);

        console.log(`💎 Added ${diamondAmount} diamonds to user ${payment.userId}`);
      }

      // === COMMIT: All operations succeed together ===
      await queryRunner.commitTransaction();
      console.log('🔒 Transaction committed successfully for payment:', payment.id);

      return { success: true, message: 'Payment processed successfully' };
    } catch (error) {
      // === ROLLBACK: If anything fails, everything is reverted ===
      await queryRunner.rollbackTransaction();

      // Check if it's a unique constraint violation (duplicate transactionId)
      if (error.code === '23505') {
        console.log('ℹ️ Duplicate transaction detected (unique constraint), already processed');
        return { success: true, message: 'Already processed' };
      }

      console.error('❌ Payment processing failed, transaction rolled back:', error);
      return { success: false, message: 'Payment processing failed' };
    } finally {
      // Always release the query runner
      await queryRunner.release();
    }
  }

  /**
   * Get user's pending payment
   */
  async getPendingPayment(userId: string): Promise<{
    hasPending: boolean;
    payment?: {
      id: string;
      paymentCode: string;
      amount: number;
      packageName: string;
      diamondAmount: number;
      createdAt: Date;
      expiresAt: Date;
    };
  }> {
    const payment = await this.paymentRepository.findOne({
      where: {
        userId,
        status: 'pending',
      },
      order: { createdAt: 'DESC' },
    });

    if (!payment) {
      return { hasPending: false };
    }

    return {
      hasPending: true,
      payment: {
        id: payment.id,
        paymentCode: payment.paymentCode,
        amount: Number(payment.amount),
        packageName: payment.packageName,
        diamondAmount: payment.diamondAmount,
        createdAt: payment.createdAt,
        expiresAt: payment.expiresAt,
      },
    };
  }

  // Clean up expired pending payments (run periodically)
  async cleanupExpiredPayments(): Promise<number> {
    const result = await this.paymentRepository.update(
      {
        status: 'pending',
        expiresAt: LessThan(new Date()),
      },
      {
        status: 'expired',
      },
    );

    return result.affected || 0;
  }
}
