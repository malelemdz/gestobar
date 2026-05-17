import { createParamDecorator, ExecutionContext, ForbiddenException } from '@nestjs/common';

export const ActiveUserId = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): string => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;

    if (!user || !user.userId) {
      throw new ForbiddenException('Usuario no autenticado');
    }

    return user.userId;
  },
);
