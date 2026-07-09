import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AuditoriaService } from './auditoria.service';
import { QueryAuditoriaDto } from './dto/query-auditoria.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { ActiveBarId } from '../auth/decorators/active-bar-id.decorator';

@Controller('auditoria')
@UseGuards(JwtAuthGuard, TenantGuard, PermissionsGuard)
export class AuditoriaController {
  constructor(private readonly auditoriaService: AuditoriaService) {}

  @Get()
  @Permissions('reportes.ver')
  findAll(
    @ActiveBarId({ optional: true }) barId: string | null,
    @Query() query: QueryAuditoriaDto,
  ) {
    return this.auditoriaService.findAll(barId, query);
  }
}
