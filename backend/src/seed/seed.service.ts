import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Role } from '../roles/entities/role.entity';
import { Permission } from '../roles/entities/permission.entity';
import { User } from '../users/entities/user.entity';
import { Bar } from '../bars/entities/bar.entity';
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
  ) {}

  async runSeed() {
    // 1. Crear Permisos del Sistema
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

    // 2. Crear Roles Básicos Globales
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
      
      // Asignar permisos correspondientes
      role.permisos = permissions.filter((p) => r.permissions.includes(p.nombre));
      await this.roleRepository.save(role);
    }

    // Obtener referencias de Roles creados
    const superAdminRole = await this.roleRepository.findOne({ where: { nombre: 'SUPERADMIN' } });
    const adminRole = await this.roleRepository.findOne({ where: { nombre: 'ADMIN' } });
    const barmanRole = await this.roleRepository.findOne({ where: { nombre: 'BARMAN' } });
    const damaRole = await this.roleRepository.findOne({ where: { nombre: 'DAMA' } });

    // 3. Crear SuperAdmin de Desarrollo (Acceso Global - bar_id null)
    let superAdmin = await this.userRepository.findOne({ where: { username: 'superadmin' } });
    if (!superAdmin) {
      superAdmin = this.userRepository.create({
        username: 'superadmin',
        password: await bcrypt.hash('superpassword', 10),
        nombre: 'Super',
        apellido: 'Admin',
        rol_id: superAdminRole!.id,
        bar_id: null,
        estado: true,
      });
      superAdmin = await this.userRepository.save(superAdmin);
    }

    // 4. Crear Bar por Defecto ("El Templo del Oro" - templo-oro)
    let bar = await this.barRepository.findOne({ where: { slug: 'templo-oro' } });
    if (!bar) {
      bar = this.barRepository.create({
        nombre: 'El Templo del Oro',
        slug: 'templo-oro',
        ciudad: 'Santa Cruz',
        direccion: 'Av. San Martín, Equipetrol',
        timezone: 'America/La_Paz',
        moneda_simbolo: 'Bs',
        moneda_iso: 'BOB',
        owner_id: superAdmin.id,
        estado: true,
      });
      bar = await this.barRepository.save(bar);
    }

    // 5. Crear Staff del Bar Asociado
    // Admin Local
    let admin = await this.userRepository.findOne({ where: { username: 'admin' } });
    if (!admin) {
      admin = this.userRepository.create({
        username: 'admin',
        password: await bcrypt.hash('adminpassword', 10),
        nombre: 'Juan',
        apellido: 'Administrador',
        rol_id: adminRole!.id,
        bar_id: bar.id,
        estado: true,
      });
      await this.userRepository.save(admin);
    }

    // Barman / Cajero
    let barman = await this.userRepository.findOne({ where: { username: 'barman' } });
    if (!barman) {
      barman = this.userRepository.create({
        username: 'barman',
        password: await bcrypt.hash('barmanpassword', 10),
        nombre: 'Carlos',
        apellido: 'Cajero',
        rol_id: barmanRole!.id,
        bar_id: bar.id,
        estado: true,
      });
      await this.userRepository.save(barman);
    }

    // Dama de Compañía
    let dama = await this.userRepository.findOne({ where: { username: 'dama' } });
    if (!dama) {
      dama = this.userRepository.create({
        username: 'dama',
        password: await bcrypt.hash('damapassword', 10),
        nombre: 'Gabriela',
        apellido: 'Compañía',
        rol_id: damaRole!.id,
        bar_id: bar.id,
        celular: '77012345',
        estado: true,
      });
      await this.userRepository.save(dama);
    }

    return { 
      message: 'Seed completado con éxito. Entorno de desarrollo listo.',
      barId: bar.id,
      credentials: {
        superadmin: 'superpassword',
        admin: 'adminpassword',
        barman: 'barmanpassword',
        dama: 'damapassword'
      }
    };
  }
}
