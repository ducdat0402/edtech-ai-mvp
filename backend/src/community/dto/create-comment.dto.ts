import { IsString, MaxLength, MinLength } from 'class-validator';

export class CreateCommunityCommentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(800)
  content: string;
}
