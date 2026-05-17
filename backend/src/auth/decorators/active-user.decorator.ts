import { createParamDecorator, ExecutionContext, ForbiddenException } from '@nestjs/common';

export class UserPayload {
  userId: string;
  rolName: string;
  barId?: string;
  email: string;
}

export const ActiveUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): UserPayload => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Usuario no autenticado');
    }

    return user;
  },
);
