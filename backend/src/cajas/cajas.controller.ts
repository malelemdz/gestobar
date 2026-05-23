import { Controller, Get, Post, Body, Param, UseGuards, ParseUUIDPipe, Req } from '@nestjs/common';
import { CajasService } from './cajas.service';
import { AperturaCajaDto } from './dto/apertura-caja.dto';
import { CierreCajaDto } from './dto/cierre-caja.dto';
import { CreateMovimientoDto } from './dto/create-movimiento.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { ActiveBarId } from '../auth/decorators/active-bar-id.decorator';
import { ActiveUser, UserPayload } from '../auth/decorators/active-user.decorator';

@Controller('cajas')
@UseGuards(JwtAuthGuard, TenantGuard, PermissionsGuard)
export class CajasController {
  constructor(private readonly cajasService: CajasService) {}

  @Get('estado')
  getEstado(@ActiveBarId() barId: string) {
    return this.cajasService.getEstado(barId);
  }

  @Post('apertura')
  @Permissions('caja.gestionar')
  apertura(
    @Body() aperturaCajaDto: AperturaCajaDto,
    @ActiveBarId() barId: string,
    @ActiveUser() user: UserPayload,
    @Req() req: any,
  ) {
    const ipAddress = req.ip || req.connection?.remoteAddress;
    const userAgent = req.headers['user-agent'];
    return this.cajasService.apertura(aperturaCajaDto, barId, user, { ipAddress, userAgent });
  }

  @Post('cierre')
  @Permissions('caja.gestionar')
  cierre(
    @Body() cierreCajaDto: CierreCajaDto,
    @ActiveBarId() barId: string,
    @ActiveUser() user: UserPayload,
    @Req() req: any,
  ) {
    const ipAddress = req.ip || req.connection?.remoteAddress;
    const userAgent = req.headers['user-agent'];
    return this.cajasService.cierre(cierreCajaDto, barId, user, { ipAddress, userAgent });
  }

  @Post('movimientos')
  @Permissions('caja.gestionar')
  registrarMovimiento(
    @Body() createMovimientoDto: CreateMovimientoDto,
    @ActiveBarId() barId: string,
    @ActiveUser() user: UserPayload,
  ) {
    return this.cajasService.registrarMovimiento(createMovimientoDto, barId, user);
  }

  @Get(':id/comisiones-damas')
  @Permissions('caja.gestionar')
  getDamaComisiones(
    @Param('id', ParseUUIDPipe) id: string,
    @ActiveBarId() barId: string,
  ) {
    return this.cajasService.getDamaComisiones(id, barId);
  }

  @Get()
  @Permissions('caja.gestionar')
  findAll(@ActiveBarId() barId: string) {
    return this.cajasService.findAll(barId);
  }

  @Get(':id')
  @Permissions('caja.gestionar')
  findOne(@Param('id', ParseUUIDPipe) id: string, @ActiveBarId() barId: string) {
    return this.cajasService.findOne(id, barId);
  }
}
