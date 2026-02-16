import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Request,
  UseGuards,
  Headers,
  HttpCode,
} from '@nestjs/common';
import { PaymentService } from './payment.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('payment')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  /**
   * Get available diamond packages
   */
  @Get('packages')
  getPackages() {
    return {
      packages: this.paymentService.getPackages(),
      bankInfo: this.paymentService.getBankInfo(),
    };
  }

  /**
   * Create a new payment order for diamonds
   */
  @Post('create')
  @UseGuards(JwtAuthGuard)
  async createPayment(
    @Request() req,
    @Body() body: { packageId: string },
  ) {
    const result = await this.paymentService.createPayment(
      req.user.id,
      body.packageId,
    );

    return {
      payment: {
        id: result.payment.id,
        paymentCode: result.payment.paymentCode,
        amount: result.payment.amount,
        packageName: result.payment.packageName,
        diamondAmount: result.payment.diamondAmount,
        status: result.payment.status,
        expiresAt: result.payment.expiresAt,
        createdAt: result.payment.createdAt,
      },
      bankInfo: result.bankInfo,
      qrUrl: result.qrContent,
      package: result.package,
    };
  }

  /**
   * Get payment details
   */
  @Get('order/:paymentId')
  @UseGuards(JwtAuthGuard)
  async getPayment(
    @Request() req,
    @Param('paymentId') paymentId: string,
  ) {
    const payment = await this.paymentService.getPayment(paymentId, req.user.id);
    return { payment };
  }

  /**
   * Get user's payment history
   */
  @Get('history')
  @UseGuards(JwtAuthGuard)
  async getPaymentHistory(@Request() req) {
    const payments = await this.paymentService.getPaymentHistory(req.user.id);
    return { payments };
  }

  /**
   * Get user's diamond balance
   */
  @Get('diamond-balance')
  @UseGuards(JwtAuthGuard)
  async getDiamondBalance(@Request() req) {
    return this.paymentService.getDiamondBalance(req.user.id);
  }

  /**
   * SePay Webhook endpoint
   * This is called by SePay when a payment is received
   */
  @Post('webhook/sepay')
  @HttpCode(200)
  async handleSepayWebhook(
    @Headers('authorization') authorization: string,
    @Body() payload: any,
  ) {
    console.log('🔔 SePay webhook called');
    console.log('Authorization:', authorization);
    
    const result = await this.paymentService.handleSepayWebhook(
      payload,
      authorization || '',
    );

    // SePay expects a 200 response
    return result;
  }

  /**
   * Manual verify (for testing/admin)
   * In production, this should be admin-only
   */
  @Post('verify-manual')
  @UseGuards(JwtAuthGuard)
  async verifyManual(
    @Body() body: { paymentCode: string; transactionId: string },
  ) {
    const mockPayload = {
      id: Date.now(),
      gateway: 'Manual',
      transactionDate: new Date().toISOString(),
      accountNumber: '0983425129',
      subAccount: null,
      code: null,
      content: body.paymentCode,
      transferType: 'in',
      description: `Manual verify: ${body.paymentCode}`,
      transferAmount: 999999999,
      referenceCode: body.transactionId,
      accumulated: 0,
    };

    return this.paymentService.handleSepayWebhook(
      mockPayload,
      `Apikey ${process.env.SEPAY_WEBHOOK_API_KEY}`,
    );
  }

  /**
   * Get user's pending payment (if any)
   */
  @Get('pending')
  @UseGuards(JwtAuthGuard)
  async getPendingPayment(@Request() req) {
    return this.paymentService.getPendingPayment(req.user.id);
  }
}
