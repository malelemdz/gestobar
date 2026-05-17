import { Controller, Get, Param, Query, UseGuards, ParseUUIDPipe, NotFoundException } from '@nestjs/common';
import { EstadisticasService } from './estadisticas.service';
import { RangoFechasDto } from './dto/rango-fechas.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { ActiveBarId } from '../auth/decorators/active-bar-id.decorator';

@Controller('estadisticas')
@UseGuards(JwtAuthGuard, TenantGuard, PermissionsGuard)
export class EstadisticasController {
  constructor(private readonly estadisticasService: EstadisticasService) {}

  @Get('resumen')
  @Permissions('reportes.ver')
  getResumenGeneral(
    @ActiveBarId() barId: string,
    @Query() query: RangoFechasDto,
  ) {
    return this.estadisticasService.getResumenGeneral(barId, query);
  }

  @Get('ranking-productos')
  @Permissions('reportes.ver')
  getRankingProductos(
    @ActiveBarId() barId: string,
    @Query() query: RangoFechasDto,
  ) {
    return this.estadisticasService.getRankingProductos(barId, query);
  }

  @Get('ranking-damas')
  @Permissions('reportes.ver')
  getRankingDamas(
    @ActiveBarId() barId: string,
    @Query() query: RangoFechasDto,
  ) {
    return this.estadisticasService.getRankingDamas(barId, query);
  }

  @Get('caja/:id')
  @Permissions('reportes.ver')
  async getStatsPorCaja(
    @ActiveBarId() barId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    const stats = await this.estadisticasService.getStatsPorCaja(barId, id);
    if (!stats) {
      throw new NotFoundException(`Sesión de caja con ID ${id} no encontrada o no pertenece a este bar.`);
    }
    return stats;
  }
}
