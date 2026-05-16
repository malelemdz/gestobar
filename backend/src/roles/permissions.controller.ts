import { Controller, Get, Post, Body } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Permission } from './entities/permission.entity';

@Controller('permissions')
export class PermissionsController {
  constructor(
    @InjectRepository(Permission)
    private readonly permissionRepository: Repository<Permission>,
  ) {}

  @Post()
  create(@Body('nombre') nombre: string) {
    const permission = this.permissionRepository.create({ nombre });
    return this.permissionRepository.save(permission);
  }

  @Get()
  findAll() {
    return this.permissionRepository.find();
  }
}
