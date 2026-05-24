import { Controller, Get, Post, Body, Param, ParseUUIDPipe, Patch, Delete, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { ActiveBarId } from '../auth/decorators/active-bar-id.decorator';
import { ActiveUserId } from '../auth/decorators/active-user-id.decorator';

@Controller('users')
@UseGuards(JwtAuthGuard, TenantGuard, PermissionsGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @Permissions('usuarios.gestionar')
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  @Permissions('usuarios.gestionar')
  findAll() {
    return this.usersService.findAll();
  }

  @Get('bar/:barId')
  @Permissions('usuarios.gestionar')
  findByBar(@Param('barId') barId: string) {
    return this.usersService.findByBar(barId);
  }

  @Get(':id')
  @Permissions('usuarios.gestionar')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.findOne(id);
  }

  @Patch('profile/update')
  updateProfile(
    @ActiveUserId() userId: string,
    @Body('password') password?: string,
    @Body('foto_url') fotoUrl?: string,
  ) {
    return this.usersService.updateProfile(userId, password, fotoUrl);
  }

  @Patch(':id')
  @Permissions('usuarios.gestionar')
  update(@Param('id', ParseUUIDPipe) id: string, @Body() updateData: any) {
    return this.usersService.update(id, updateData);
  }

  @Delete(':id')
  @Permissions('usuarios.gestionar')
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.remove(id);
  }
}

