import { Injectable, NotFoundException, ConflictException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, IsNull } from 'typeorm';
import { Role } from './entities/role.entity';
import { Permission } from './entities/permission.entity';

@Injectable()
export class RolesService {
  constructor(
    @InjectRepository(Role)
    private readonly roleRepository: Repository<Role>,
    @InjectRepository(Permission)
    private readonly permissionRepository: Repository<Permission>,
  ) {}

  async create(nombre: string, bar_id?: string, permiso_ids?: string[]): Promise<Role> {
    let permisos: Permission[] = [];
    if (permiso_ids && permiso_ids.length > 0) {
      permisos = await this.permissionRepository.find({
        where: { id: In(permiso_ids) },
      });
    }

    const role = this.roleRepository.create({
      nombre,
      bar_id: bar_id || null,
      permisos,
    });
    return await this.roleRepository.save(role);
  }

  async findAll(): Promise<Role[]> {
    return await this.roleRepository.find({ relations: ['permisos'] });
  }

  async findOne(id: string): Promise<Role> {
    const role = await this.roleRepository.findOne({ where: { id } });
    if (!role) {
      throw new NotFoundException(`Rol con ID ${id} no encontrado`);
    }
    return role;
  }

  async findOneWithPermissions(id: string): Promise<Role> {
    const role = await this.roleRepository.findOne({
      where: { id },
      relations: ['permisos'],
    });
    if (!role) {
      throw new NotFoundException(`Rol con ID ${id} no encontrado`);
    }
    return role;
  }

  async findByBar(bar_id: string): Promise<Role[]> {
    return await this.roleRepository.find({
      where: [
        { bar_id },
        { bar_id: IsNull(), nombre: In(['ADMIN', 'BARMAN', 'DAMA']) }
      ],
      relations: ['permisos'],
      order: {
        nombre: 'ASC'
      }
    });
  }

  async update(id: string, nombre: string, permiso_ids: string[]): Promise<Role> {
    const role = await this.findOneWithPermissions(id);
    
    // Solo permitir editar roles de sucursal (bar_id no nulo)
    if (!role.bar_id) {
      throw new ForbiddenException('No se pueden editar roles globales del sistema');
    }

    let permisos: Permission[] = [];
    if (permiso_ids && permiso_ids.length > 0) {
      permisos = await this.permissionRepository.find({
        where: { id: In(permiso_ids) },
      });
    }

    role.nombre = nombre;
    role.permisos = permisos;
    return await this.roleRepository.save(role);
  }

  async remove(id: string, bar_id: string): Promise<void> {
    const role = await this.findOne(id);

    // Impedir borrar roles globales del sistema
    if (!role.bar_id) {
      throw new ForbiddenException('No se pueden eliminar roles globales del sistema');
    }

    // Aislamiento por tenant
    if (role.bar_id !== bar_id) {
      throw new ForbiddenException('No tienes permisos para eliminar este rol');
    }

    await this.roleRepository.remove(role);
  }
}
