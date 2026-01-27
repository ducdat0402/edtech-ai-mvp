import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { Payment, PaymentStatus } from './entities/payment.entity';
import { UserPremium } from './entities/user-premium.entity';
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

// Payment packages
export interface PaymentPackage {
  id: string;
  name: string;
  price: number;
  durationDays: number;
  description: string;
  features: string[];
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
      id: 'premium_1month',
      name: 'Premium 1 Tháng',
      price: 50000,
      durationDays: 30,
      description: 'Trải nghiệm đầy đủ tính năng trong 1 tháng',
      features: [
        'Không giới hạn quiz',
        'Truy cập tất cả bài học',
        'Không quảng cáo',
        'Hỗ trợ ưu tiên',
      ],
    },
    {
      id: 'premium_3months',
      name: 'Premium 3 Tháng',
      price: 120000,
      durationDays: 90,
      description: 'Tiết kiệm 20% so với gói 1 tháng',
      features: [
        'Tất cả tính năng Premium',
        'Tiết kiệm 20%',
        'Badge độc quyền',
      ],
    },
    {
      id: 'premium_1year',
      name: 'Premium 1 Năm',
      price: 400000,
      durationDays: 365,
      description: 'Tiết kiệm 33% - Đầu tư cho tương lai',
      features: [
        'Tất cả tính năng Premium',
        'Tiết kiệm 33%',
        'Badge độc quyền',
        'Ưu tiên tính năng mới',
      ],
    },
  ];

  constructor(
    @InjectRepository(Payment)
    private paymentRepository: Repository<Payment>,
    @InjectRepository(UserPremium)
    private userPremiumRepository: Repository<UserPremium>,
    private configService: ConfigService,
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

  // Create a new payment order
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

    // Check for existing pending payment
    const existingPending = await this.paymentRepository.findOne({
      where: {
        userId,
        status: 'pending',
      },
    });

    if (existingPending) {
      // Cancel old pending payment
      existingPending.status = 'cancelled';
      await this.paymentRepository.save(existingPending);
    }

    // Create new payment
    const paymentCode = this.generatePaymentCode();
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24); // 24 hours to pay

    const payment = this.paymentRepository.create({
      userId,
      paymentCode,
      packageName: pkg.name,
      amount: pkg.price,
      description: pkg.description,
      durationDays: pkg.durationDays,
      status: 'pending',
      expiresAt,
    });

    await this.paymentRepository.save(payment);

    // Generate QR content (VietQR format)
    const qrContent = this.generateVietQRContent(pkg.price, paymentCode);

    return {
      payment,
      bankInfo: this.bankInfo,
      qrContent,
      package: pkg,
    };
  }

  // Generate VietQR content string
  private generateVietQRContent(amount: number, content: string): string {
    // VietQR URL format for QR code
    // https://img.vietqr.io/image/{bankCode}-{accountNumber}-compact.png?amount={amount}&addInfo={content}
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

  // Get user's premium status
  async getPremiumStatus(userId: string): Promise<{
    isPremium: boolean;
    expiresAt: Date | null;
    daysRemaining: number;
  }> {
    let userPremium = await this.userPremiumRepository.findOne({
      where: { userId },
    });

    if (!userPremium) {
      return {
        isPremium: false,
        expiresAt: null,
        daysRemaining: 0,
      };
    }

    // Check if premium has expired
    const now = new Date();
    if (userPremium.premiumExpiresAt && userPremium.premiumExpiresAt < now) {
      userPremium.isPremium = false;
      await this.userPremiumRepository.save(userPremium);
    }

    const daysRemaining = userPremium.premiumExpiresAt
      ? Math.max(0, Math.ceil((userPremium.premiumExpiresAt.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)))
      : 0;

    return {
      isPremium: userPremium.isPremium,
      expiresAt: userPremium.premiumExpiresAt,
      daysRemaining,
    };
  }

  // Handle SePay webhook
  async handleSepayWebhook(
    payload: SepayWebhookPayload,
    apiKey: string,
  ): Promise<{ success: boolean; message: string }> {
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
    console.log('🔍 Looking for payment code:', paymentCode);

    // Find pending payment
    const payment = await this.paymentRepository.findOne({
      where: {
        paymentCode,
        status: 'pending',
      },
    });

    if (!payment) {
      console.log('⚠️ Payment not found or not pending:', paymentCode);
      return { success: false, message: 'Payment not found' };
    }

    // Verify amount
    if (payload.transferAmount < payment.amount) {
      console.log(`⚠️ Amount mismatch: received ${payload.transferAmount}, expected ${payment.amount}`);
      return { success: false, message: 'Amount mismatch' };
    }

    // Update payment status
    payment.status = 'paid';
    payment.transactionId = payload.id.toString();
    payment.bankReference = payload.referenceCode;
    payment.paidAt = new Date();
    await this.paymentRepository.save(payment);

    console.log('✅ Payment marked as paid:', payment.id);

    // Activate premium for user
    await this.activatePremium(payment.userId, payment.durationDays, payment.id);

    console.log('✅ Premium activated for user:', payment.userId);

    return { success: true, message: 'Payment processed successfully' };
  }

  // Activate premium for user
  private async activatePremium(
    userId: string,
    durationDays: number,
    paymentId: string,
  ): Promise<void> {
    let userPremium = await this.userPremiumRepository.findOne({
      where: { userId },
    });

    const now = new Date();
    let newExpiresAt: Date;

    if (userPremium) {
      // Extend existing premium
      if (userPremium.isPremium && userPremium.premiumExpiresAt > now) {
        // Add days to existing expiry
        newExpiresAt = new Date(userPremium.premiumExpiresAt);
      } else {
        // Start fresh from now
        newExpiresAt = new Date();
      }
      newExpiresAt.setDate(newExpiresAt.getDate() + durationDays);

      userPremium.isPremium = true;
      userPremium.premiumExpiresAt = newExpiresAt;
      userPremium.totalDaysPurchased += durationDays;
      userPremium.lastPaymentId = paymentId;
    } else {
      // Create new premium record
      newExpiresAt = new Date();
      newExpiresAt.setDate(newExpiresAt.getDate() + durationDays);

      userPremium = this.userPremiumRepository.create({
        userId,
        isPremium: true,
        premiumExpiresAt: newExpiresAt,
        totalDaysPurchased: durationDays,
        lastPaymentId: paymentId,
      });
    }

    await this.userPremiumRepository.save(userPremium);
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
