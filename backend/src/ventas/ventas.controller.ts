import { Controller, Get, Post, Body, Param, UseGuards, ParseUUIDPipe, Req } from '@nestjs/common';
import { VentasService } from './ventas.service';
import { CreateVentaDto } from './dto/create-venta.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { ActiveBarId } from '../auth/decorators/active-bar-id.decorator';
import { ActiveUserId } from '../auth/decorators/active-user-id.decorator';
import { ActiveUser, UserPayload } from '../auth/decorators/active-user.decorator';

@Controller('ventas')
@UseGuards(JwtAuthGuard, TenantGuard, PermissionsGuard)
export class VentasController {
  constructor(private readonly ventasService: VentasService) {}

  @Post()
  @Permissions('ventas.registrar')
  create(
    @Body() createVentaDto: CreateVentaDto,
    @ActiveBarId() barId: string,
    @ActiveUser() user: UserPayload,
    @Req() req: any,
  ) {
    const ipAddress = req.ip || req.connection?.remoteAddress;
    const userAgent = req.headers['user-agent'];
    return this.ventasService.create(createVentaDto, barId, user, { ipAddress, userAgent });
  }

  @Get('comisiones')
  @Permissions('comisiones.ver_propias')
  getDamaComisiones(@ActiveUserId() damaId: string, @ActiveBarId() barId: string) {
    return this.ventasService.getDamaComisiones(damaId, barId);
  }

  @Get('caja/activa')
  @Permissions('reportes.ver')
  getActiveVentas(@ActiveBarId() barId: string) {
    return this.ventasService.getActiveVentas(barId);
  }

  @Get('caja/:cajaId')
  @Permissions('caja.historial')
  getVentasByCaja(@Param('cajaId', ParseUUIDPipe) cajaId: string, @ActiveBarId() barId: string) {
    return this.ventasService.getVentasByCaja(cajaId, barId);
  }

  @Get()
  @Permissions('reportes.ver')
  findAll(@ActiveBarId() barId: string) {
    return this.ventasService.findAll(barId);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string, @ActiveBarId() barId: string) {
    return this.ventasService.findOne(id, barId);
  }
}
