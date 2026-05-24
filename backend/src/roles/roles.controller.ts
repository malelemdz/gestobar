import { Controller, Get, Post, Patch, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { RolesService } from './roles.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { ActiveBarId } from '../auth/decorators/active-bar-id.decorator';

@Controller('roles')
@UseGuards(JwtAuthGuard, TenantGuard, PermissionsGuard)
export class RolesController {
  constructor(private readonly rolesService: RolesService) {}

  @Post()
  @Permissions('usuarios.gestionar')
  create(
    @Body('nombre') nombre: string,
    @Body('permiso_ids') permisoIds: string[],
    @ActiveBarId() barId: string,
  ) {
    return this.rolesService.create(nombre, barId, permisoIds);
  }

  @Get()
  findAll() {
    return this.rolesService.findAll();
  }

  @Get('bar/:barId')
  findByBar(@Param('barId') barId: string) {
    return this.rolesService.findByBar(barId);
  }

  @Patch(':id')
  @Permissions('usuarios.gestionar')
  update(
    @Param('id') id: string,
    @Body('nombre') nombre: string,
    @Body('permiso_ids') permisoIds: string[],
  ) {
    return this.rolesService.update(id, nombre, permisoIds);
  }

  @Delete(':id')
  @Permissions('usuarios.gestionar')
  remove(
    @Param('id') id: string,
    @ActiveBarId() barId: string,
  ) {
    return this.rolesService.remove(id, barId);
  }
}

