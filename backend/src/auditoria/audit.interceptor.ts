import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { ClsService } from 'nestjs-cls';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly cls: ClsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    
    // Capturamos los datos solo si es una petición web real y el usuario ya pasó por el guard
    if (req && req.user) {
      this.cls.set('user', req.user);
      this.cls.set('ip', req.ip || req.headers['x-forwarded-for']);
      this.cls.set('userAgent', req.headers['user-agent']);
    }

    return next.handle();
  }
}
