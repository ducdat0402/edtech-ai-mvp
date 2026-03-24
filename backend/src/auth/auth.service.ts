import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { OAuth2Client } from 'google-auth-library';
import * as crypto from 'crypto';
import * as bcrypt from 'bcrypt';
import * as nodemailer from 'nodemailer';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;

  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {
    const googleClientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    this.googleClient = new OAuth2Client(googleClientId);
  }

  async register(registerDto: RegisterDto) {
    const existingUser = await this.usersService.findByEmail(registerDto.email);
    if (existingUser) {
      throw new ConflictException('Email already exists');
    }

    const user = await this.usersService.create(
      registerDto.email,
      registerDto.password,
      registerDto.fullName,
    );

    const payload = { sub: user.id, email: user.email };
    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl ?? null,
      },
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.usersService.findByEmail(loginDto.email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await this.usersService.validatePassword(
      user,
      loginDto.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const payload = { sub: user.id, email: user.email };
    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl ?? null,
        currentStreak: user.currentStreak,
        totalXP: user.totalXP,
      },
    };
  }

  async googleLogin(idToken: string) {
    const googleClientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    if (!googleClientId) {
      throw new BadRequestException('Google Sign-In chưa được cấu hình');
    }

    let email: string;
    let name: string | undefined;
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: googleClientId,
      });
      const payload = ticket.getPayload();
      if (!payload?.email) {
        throw new Error('No email in token');
      }
      email = payload.email;
      name = payload.name;
    } catch {
      throw new UnauthorizedException('Token Google không hợp lệ');
    }

    const user = await this.usersService.findOrCreateGoogleUser(email, name);

    const jwtPayload = { sub: user.id, email: user.email };
    const accessToken = this.jwtService.sign(jwtPayload);

    return {
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl ?? null,
        currentStreak: user.currentStreak,
        totalXP: user.totalXP,
      },
    };
  }

  async forgotPassword(email: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      return { message: 'Nếu email tồn tại, bạn sẽ nhận được link đặt lại mật khẩu.' };
    }

    const token = crypto.randomBytes(32).toString('hex');
    const expires = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes
    await this.usersService.setResetToken(user.id, token, expires);

    const frontendUrl = this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000';
    const resetUrl = `${frontendUrl}/reset-password.html?token=${token}`;

    try {
      await this.sendResetEmail(user.email, user.fullName || 'bạn', resetUrl);
    } catch (err) {
      console.error('Failed to send reset email:', err);
      throw new BadRequestException('Không gửi được email. Vui lòng thử lại sau.');
    }

    return { message: 'Nếu email tồn tại, bạn sẽ nhận được link đặt lại mật khẩu.' };
  }

  async resetPassword(token: string, newPassword: string) {
    if (!token || !newPassword || newPassword.length < 6) {
      throw new BadRequestException('Mật khẩu phải có ít nhất 6 ký tự');
    }

    const user = await this.usersService.findByResetToken(token);
    if (!user || !user.resetPasswordExpires) {
      throw new NotFoundException('Token không hợp lệ hoặc đã hết hạn');
    }

    if (user.resetPasswordExpires < new Date()) {
      throw new BadRequestException('Token đã hết hạn. Vui lòng yêu cầu lại.');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await this.usersService.updatePassword(user.id, hashedPassword);

    return { message: 'Mật khẩu đã được đặt lại thành công.' };
  }

  async verifyToken(token: string) {
    try {
      const payload = this.jwtService.verify(token);
      const user = await this.usersService.findById(payload.sub);
      if (!user) {
        throw new UnauthorizedException('User not found');
      }
      return {
        valid: true,
        user: {
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          avatarUrl: user.avatarUrl ?? null,
          currentStreak: user.currentStreak,
          totalXP: user.totalXP,
        },
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }

  private async sendResetEmail(to: string, name: string, resetUrl: string): Promise<void> {
    const host = this.configService.get<string>('SMTP_HOST');
    const port = parseInt(this.configService.get<string>('SMTP_PORT') || '587', 10);
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');

    if (!host || !user || !pass) {
      throw new Error('SMTP chưa được cấu hình');
    }

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    });

    await transporter.sendMail({
      from: `"EdTech AI" <${user}>`,
      to,
      subject: 'Đặt lại mật khẩu – EdTech AI',
      html: `
        <div style="max-width:480px;margin:auto;font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;padding:32px;border-radius:16px;">
          <h2 style="color:#00d4ff;text-align:center;">EdTech AI</h2>
          <p>Xin chào <strong>${name}</strong>,</p>
          <p>Bạn (hoặc ai đó) đã yêu cầu đặt lại mật khẩu cho tài khoản này.</p>
          <div style="text-align:center;margin:24px 0;">
            <a href="${resetUrl}" style="display:inline-block;padding:14px 32px;background:linear-gradient(135deg,#7c3aed,#ec4899);color:#fff;text-decoration:none;border-radius:12px;font-weight:bold;">Đặt lại mật khẩu</a>
          </div>
          <p style="font-size:13px;color:#999;">Link có hiệu lực trong 30 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.</p>
        </div>
      `,
    });
  }
}
