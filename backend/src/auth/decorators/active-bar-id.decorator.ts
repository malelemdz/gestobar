import { createParamDecorator, ExecutionContext, ForbiddenException } from '@nestjs/common';

export const ActiveBarId = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): string => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Usuario no autenticado');
    }

    if (user.rolName === 'SUPERADMIN') {
      const headerBarId = request.headers['x-bar-id'];
      if (!headerBarId) {
        throw new ForbiddenException('Como SUPERADMIN, debes especificar el bar en el header x-bar-id para esta acción.');
      }
      return headerBarId as string;
    }

    if (!user.barId) {
      throw new ForbiddenException('El usuario no tiene un Bar asignado.');
    }

    return user.barId;
  },
);
