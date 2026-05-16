import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { RolesService } from './roles.service';

@Controller('roles')
export class RolesController {
  constructor(private readonly rolesService: RolesService) {}

  @Post()
  create(@Body('nombre') nombre: string, @Body('bar_id') bar_id?: string) {
    return this.rolesService.create(nombre, bar_id);
  }

  @Get()
  findAll() {
    return this.rolesService.findAll();
  }

  @Get('bar/:barId')
  findByBar(@Param('barId') barId: string) {
    return this.rolesService.findByBar(barId);
  }
}
