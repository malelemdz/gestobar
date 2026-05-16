import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';

@Injectable()
export class TenantGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      return false;
    }

    // SUPERADMIN es el único que puede tener barId null (acceso global)
    if (user.rolName === 'SUPERADMIN') {
      return true;
    }

    // Para cualquier otro rol, barId DEBE estar presente
    if (!user.barId) {
      throw new ForbiddenException('El usuario no tiene un Bar asignado y no posee rango SUPERADMIN.');
    }

    return true;
  }
}
