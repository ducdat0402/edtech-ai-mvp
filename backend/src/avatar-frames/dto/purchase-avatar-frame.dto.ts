import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class PurchaseAvatarFrameDto {
  @IsString()
  @IsNotEmpty()
  frameId: string;

  /** Bắt buộc khi khung `choice`; bỏ qua với chỉ GTU hoặc chỉ kim cương. */
  @IsOptional()
  @IsIn(['coins', 'diamonds'])
  currency?: 'coins' | 'diamonds';
}
