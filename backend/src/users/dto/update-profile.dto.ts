import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  fullName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2048)
  /** Đường dẫn từ server (vd. `/uploads/images/...`) hoặc URL đầy đủ. Chuỗi rỗng = xóa ảnh. */
  avatarUrl?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  phone?: string;
}
