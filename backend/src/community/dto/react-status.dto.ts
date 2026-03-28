import { IsIn, IsString } from 'class-validator';

export class ReactCommunityStatusDto {
  @IsString()
  @IsIn(['like', 'dislike'])
  kind: 'like' | 'dislike';
}
