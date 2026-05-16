import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Role } from '../roles/entities/role.entity';
import { Permission } from '../roles/entities/permission.entity';

@Injectable()
export class SeedService {
  constructor(
    @InjectRepository(Role)
    private readonly roleRepository: Repository<Role>,
    @InjectRepository(Permission)
    private readonly permissionRepository: Repository<Permission>,
  ) {}

  async runSeed() {
    // 1. Crear Permisos
    const permissionsData = [
      { nombre: 'bares.gestionar' },
      { nombre: 'usuarios.gestionar' },
      { nombre: 'roles.gestionar' },
      { nombre: 'productos.gestionar' },
      { nombre: 'ventas.registrar' },
      { nombre: 'caja.gestionar' },
      { nombre: 'comisiones.ver_propias' },
      { nombre: 'reportes.ver' },
      { nombre: 'revision.lectura' },
    ];

    const permissions: Permission[] = [];
    for (const p of permissionsData) {
      let permission = await this.permissionRepository.findOne({ where: { nombre: p.nombre } });
      if (!permission) {
        permission = await this.permissionRepository.save(this.permissionRepository.create(p));
      }
      permissions.push(permission);
    }

    // 2. Crear Roles Básicos y Asignar Permisos
    const rolesData = [
      { nombre: 'SUPERADMIN', permissions: ['bares.gestionar', 'usuarios.gestionar', 'reportes.ver'] },
      { nombre: 'ADMIN', permissions: ['usuarios.gestionar', 'roles.gestionar', 'productos.gestionar', 'caja.gestionar', 'reportes.ver'] },
      { nombre: 'BARMAN', permissions: ['ventas.registrar', 'caja.gestionar'] },
      { nombre: 'DAMA', permissions: ['comisiones.ver_propias'] },
      { nombre: 'REVIEWER', permissions: ['revision.lectura'] },
    ];

    for (const r of rolesData) {
      let role = await this.roleRepository.findOne({ 
        where: { nombre: r.nombre, bar_id: IsNull() } 
      });
      
      if (!role) {
        role = this.roleRepository.create({ 
          nombre: r.nombre,
          bar_id: null 
        });
      }
      
      // Asignar permisos según la data
      role.permisos = permissions.filter((p) => r.permissions.includes(p.nombre));
      await this.roleRepository.save(role);
    }

    return { message: 'Seed ejecutado con éxito' };
  }
}
