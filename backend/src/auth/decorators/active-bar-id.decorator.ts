import { createParamDecorator, ExecutionContext, ForbiddenException } from '@nestjs/common';

export const ActiveBarId = createParamDecorator(
  (data: { optional?: boolean } | undefined, ctx: ExecutionContext): string | null => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Usuario no autenticado');
    }

    if (user.rolName === 'SUPERADMIN') {
      const headerBarId = request.headers['x-bar-id'];
      if (!headerBarId) {
        if (data && data.optional === true) {
          return null;
        }
        throw new ForbiddenException('Como SUPERADMIN, debes especificar el bar en el header x-bar-id para esta acción.');
      }
      return headerBarId as string;
    }

    if (!user.barId) {
      if (data && data.optional === true) {
        return null;
      }
      throw new ForbiddenException('El usuario no tiene un Bar asignado.');
    }

    return user.barId;
  },
);
