import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards, Request, ForbiddenException, ParseUUIDPipe } from '@nestjs/common';
import { TarifasService } from './tarifas.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';

@Controller('tarifas')
@UseGuards(JwtAuthGuard, TenantGuard)
export class TarifasController {
  constructor(private readonly tarifasService: TarifasService) {}

  @Post()
  create(
    @Body('bar_id', ParseUUIDPipe) barId: string,
    @Body('nombre') nombre: string,
    @Body('es_default') esDefault: boolean,
    @Body('activo') activo: boolean,
    @Request() req
  ) {
    if (req.user.rolName !== 'SUPERADMIN' && req.user.barId !== barId) {
      throw new ForbiddenException('No tienes permisos para crear tarifas en este bar');
    }
    return this.tarifasService.create(barId, nombre, esDefault ?? false, activo ?? true);
  }

  @Get('bar/:barId')
  findAllByBar(@Param('barId', ParseUUIDPipe) barId: string, @Request() req) {
    if (req.user.rolName !== 'SUPERADMIN' && req.user.barId !== barId) {
      throw new ForbiddenException('No tienes acceso a las tarifas de este bar');
    }
    return this.tarifasService.findAllByBar(barId);
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string, @Request() req) {
    const tarifa = await this.tarifasService.findOne(id);
    if (req.user.rolName !== 'SUPERADMIN' && req.user.barId !== tarifa.bar_id) {
      throw new ForbiddenException('No tienes acceso a esta tarifa');
    }
    return tarifa;
  }

  @Put(':id')
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('nombre') nombre: string,
    @Body('es_default') esDefault: boolean,
    @Body('activo') activo: boolean,
    @Request() req
  ) {
    const tarifa = await this.tarifasService.findOne(id);
    if (req.user.rolName !== 'SUPERADMIN' && req.user.barId !== tarifa.bar_id) {
      throw new ForbiddenException('No tienes permisos para editar esta tarifa');
    }
    return this.tarifasService.update(id, nombre, esDefault, activo);
  }

  @Delete(':id')
  async remove(@Param('id', ParseUUIDPipe) id: string, @Request() req) {
    const tarifa = await this.tarifasService.findOne(id);
    if (req.user.rolName !== 'SUPERADMIN' && req.user.barId !== tarifa.bar_id) {
      throw new ForbiddenException('No tienes permisos para eliminar esta tarifa');
    }
    if (tarifa.es_default) {
      throw new ForbiddenException('No se puede eliminar la tarifa por defecto del bar');
    }
    await this.tarifasService.remove(id);
    return { success: true };
  }
}

