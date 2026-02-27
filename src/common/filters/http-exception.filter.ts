import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    // Ignore favicon requests - just return 204 No Content
    if (request.url.includes('favicon.ico')) {
      return response.status(204).end();
    }

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    const errorResponse = {
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      method: request.method,
      message:
        typeof message === 'string'
          ? message
          : (message as any).message || 'An error occurred',
      error:
        typeof message === 'object' && (message as any).error
          ? (message as any).error
          : undefined,
    };

    // Only log errors that are not 404 for favicon or common browser requests
    const isCommonBrowserRequest = 
      request.url.includes('favicon.ico') ||
      request.url.includes('robots.txt') ||
      request.url.includes('.ico');

    // Log error in development (skip common browser requests)
    if (process.env.NODE_ENV === 'development' && !isCommonBrowserRequest) {
      if (status >= 500) {
        console.error('Exception:', exception);
      } else if (status === 404 && !isCommonBrowserRequest) {
        // Only log 404 if it's not a common browser request
        console.warn(`404 Not Found: ${request.method} ${request.url}`);
      }
    }

    response.status(status).json(errorResponse);
  }
}

