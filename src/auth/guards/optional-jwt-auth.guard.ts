import { Injectable, ExecutionContext } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Optional JWT Auth Guard
 * Allows both authenticated and unauthenticated requests
 * If token is valid, sets req.user; otherwise, req.user is undefined
 */
@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    // Add your custom authentication logic here
    // for example, call super.logIn(request) to establish a session.
    return super.canActivate(context);
  }

  handleRequest(err: any, user: any) {
    // If there's an error or no user, just return null (don't throw)
    // This allows unauthenticated requests to pass through
    if (err || !user) {
      return null;
    }
    return user;
  }
}
