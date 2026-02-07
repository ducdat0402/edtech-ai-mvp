import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { UsersService } from '../../users/users.service';

@Injectable()
export class ContributorGuard implements CanActivate {
  constructor(private usersService: UsersService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user || !user.id) {
      throw new ForbiddenException('Authentication required');
    }

    const dbUser = await this.usersService.findById(user.id);
    if (!dbUser || (dbUser.role !== 'contributor' && dbUser.role !== 'admin')) {
      throw new ForbiddenException(
        'Contributor access required. Please switch to Contributor mode in your profile.',
      );
    }

    return true;
  }
}
