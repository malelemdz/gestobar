import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull, DataSource } from 'typeorm';
import { Role } from '../roles/entities/role.entity';
import { Permission } from '../roles/entities/permission.entity';
import { User } from '../users/entities/user.entity';
import { Bar } from '../bars/entities/bar.entity';
import { Category } from '../categories/entities/category.entity';
import { Product } from '../products/entities/product.entity';
import { Tarifa } from '../tarifas/entities/tarifa.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class SeedService {
  constructor(
    @InjectRepository(Role)
    private readonly roleRepository: Repository<Role>,
    @InjectRepository(Permission)
    private readonly permissionRepository: Repository<Permission>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Bar)
    private readonly barRepository: Repository<Bar>,
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    @InjectRepository(Tarifa)
    private readonly tarifaRepository: Repository<Tarifa>,
    private readonly dataSource: DataSource,
  ) {}

  async runSeed() {
    // 0. Resetear Base de Datos completamente (Drop & Sync)
    await this.dataSource.synchronize(true);

    // 1. Crear Permisos del Sistema
    const permissionsData = [
      { nombre: 'bares.gestionar' },
      { nombre: 'usuarios.gestionar' },
      { nombre: 'roles.gestionar' },
      { nombre: 'productos.gestionar' },
      { nombre: 'ventas.registrar' },
      { nombre: 'caja.gestionar' },
      { nombre: 'caja.historial' },
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

    // 2. Crear Roles Básicos Globales
    const rolesData = [
      { nombre: 'SUPERADMIN', permissions: ['bares.gestionar', 'usuarios.gestionar', 'reportes.ver', 'caja.historial'] },
      { nombre: 'ADMIN', permissions: ['usuarios.gestionar', 'roles.gestionar', 'productos.gestionar', 'caja.gestionar', 'reportes.ver', 'ventas.registrar', 'caja.historial'] },
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
      
      // Asignar permisos correspondientes
      role.permisos = permissions.filter((p) => r.permissions.includes(p.nombre));
      await this.roleRepository.save(role);
    }

    // Obtener referencias de Roles creados
    const superAdminRole = await this.roleRepository.findOne({ where: { nombre: 'SUPERADMIN' } });

    // 3. Crear SuperAdmin (Acceso Global - bar_id null)
    const superAdminUsername = process.env.SUPERADMIN_USERNAME || 'superadmin';
    const superAdminPassword = process.env.SUPERADMIN_PASSWORD || 'superpassword';

    let superAdmin = this.userRepository.create({
      username: superAdminUsername,
      password: await bcrypt.hash(superAdminPassword, 10),
      nombre: process.env.SUPERADMIN_NOMBRE || 'Super',
      apellido: process.env.SUPERADMIN_APELLIDO || 'Admin',
      rol_id: superAdminRole!.id,
      bar_id: null,
      genero: 'PREFIERO_NO_DECIRLO',
      estado: true,
    });
    superAdmin = await this.userRepository.save(superAdmin);

    return { 
      message: 'Base de datos reseteada con éxito. El sistema ha nacido virgen con solo el usuario SUPERADMIN.',
      credentials: {
        superadmin: {
          username: superAdminUsername,
          password: 'Password configurado en variables de entorno'
        }
      }
    };
  }
}
