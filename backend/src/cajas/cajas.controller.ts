import { Controller, Get, Post, Body, Param, UseGuards, ParseUUIDPipe } from '@nestjs/common';
import { CajasService } from './cajas.service';
import { AperturaCajaDto } from './dto/apertura-caja.dto';
import { CierreCajaDto } from './dto/cierre-caja.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { ActiveBarId } from '../auth/decorators/active-bar-id.decorator';
import { ActiveUserId } from '../auth/decorators/active-user-id.decorator';

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
    @ActiveUserId() userId: string,
  ) {
    return this.cajasService.apertura(aperturaCajaDto, barId, userId);
  }

  @Post('cierre')
  @Permissions('caja.gestionar')
  cierre(
    @Body() cierreCajaDto: CierreCajaDto,
    @ActiveBarId() barId: string,
    @ActiveUserId() userId: string,
  ) {
    return this.cajasService.cierre(cierreCajaDto, barId, userId);
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
