import { Controller, Get, Post, Body, Patch, Param, Delete, ParseUUIDPipe, UseGuards, Request, ForbiddenException } from '@nestjs/common';
import { BarsService } from './bars.service';
import { CreateBarDto } from './dto/create-bar.dto';
import { UpdateBarDto } from './dto/update-bar.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';

@Controller('bars')
@UseGuards(JwtAuthGuard, TenantGuard)
export class BarsController {
  constructor(private readonly barsService: BarsService) {}

  @Post()
  create(@Body() createBarDto: CreateBarDto, @Request() req) {
    if (req.user.rolName !== 'SUPERADMIN') {
      throw new ForbiddenException('Solo un SUPERADMIN puede crear un nuevo bar');
    }
    return this.barsService.create(createBarDto);
  }

  @Get()
  findAll(@Request() req) {
    if (req.user.rolName !== 'SUPERADMIN') {
      throw new ForbiddenException('Solo un SUPERADMIN puede ver la lista de todos los bares');
    }
    return this.barsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string, @Request() req) {
    if (req.user.rolName !== 'SUPERADMIN' && req.user.barId !== id) {
      throw new ForbiddenException('No tienes acceso a la información de este bar');
    }
    return this.barsService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateBarDto: UpdateBarDto,
    @Request() req,
  ) {
    if (req.user.rolName !== 'SUPERADMIN' && req.user.barId !== id) {
      throw new ForbiddenException('No tienes permisos para modificar la configuración de este bar');
    }
    return this.barsService.update(id, updateBarDto);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string, @Request() req) {
    if (req.user.rolName !== 'SUPERADMIN') {
      throw new ForbiddenException('Solo un SUPERADMIN puede eliminar un bar');
    }
    return this.barsService.remove(id);
  }
}

