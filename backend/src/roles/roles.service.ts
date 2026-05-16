import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Role } from './entities/role.entity';

@Injectable()
export class RolesService {
  constructor(
    @InjectRepository(Role)
    private readonly roleRepository: Repository<Role>,
  ) {}

  async create(nombre: string, bar_id?: string): Promise<Role> {
    const role = this.roleRepository.create({ nombre, bar_id });
    return await this.roleRepository.save(role);
  }

  async findAll(): Promise<Role[]> {
    return await this.roleRepository.find();
  }

  async findByBar(bar_id: string): Promise<Role[]> {
    return await this.roleRepository.find({ where: { bar_id } });
  }
}
