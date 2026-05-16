import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from '../decorators/permissions.decorator';
import { RolesService } from '../../roles/roles.service';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private rolesService: RolesService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(PERMISSIONS_KEY, [
      context.getHandler(),
      context.getClasses(),
    ]);

    if (!requiredPermissions) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest();
    if (!user || !user.rolId) {
      throw new ForbiddenException('No tienes permisos para realizar esta acción');
    }

    const role = await this.rolesService.findOneWithPermissions(user.rolId);
    if (!role) {
      throw new ForbiddenException('Rol no encontrado');
    }

    // SuperAdmin tiene acceso total siempre
    if (role.nombre === 'SUPERADMIN') {
      return true;
    }

    const userPermissions = role.permisos.map((p) => p.nombre);
    const hasPermission = requiredPermissions.every((permission) =>
      userPermissions.includes(permission),
    );

    if (!hasPermission) {
      throw new ForbiddenException('No tienes los permisos necesarios');
    }

    return true;
  }
}
