import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
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
        genero: 'PREFIERO_NO_DECIRLO',
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

    // 4.5 Obtener o Crear la única Tarifa por Defecto (Normal) para el bar
    let tarifaGeneral = await this.tarifaRepository.findOne({ where: { es_default: true, bar_id: bar.id } });
    if (!tarifaGeneral) {
      tarifaGeneral = await this.tarifaRepository.findOne({ where: { nombre: 'Normal', bar_id: bar.id } });
    }
    if (!tarifaGeneral) {
      tarifaGeneral = await this.tarifaRepository.save(this.tarifaRepository.create({ nombre: 'Normal', es_default: true, bar_id: bar.id }));
    }
    
    // Buscar si ya existe la tarifa de compañía en la base de datos (sin crearla)
    let tarifaCompania = await this.tarifaRepository.findOne({ where: { nombre: 'Compania', bar_id: bar.id } });
    if (!tarifaCompania) {
      tarifaCompania = await this.tarifaRepository.findOne({ where: { nombre: 'Compañía', bar_id: bar.id } });
    }

    // Asignar al bar
    bar.modulo_damas_activo = true;
    const companiaTarifaId = tarifaCompania ? tarifaCompania.id : tarifaGeneral.id;
    if (tarifaCompania) {
      bar.tarifa_compania_id = tarifaCompania.id;
    }
    await this.barRepository.save(bar);

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
        genero: 'PREFIERO_NO_DECIRLO',
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
        genero: 'PREFIERO_NO_DECIRLO',
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
        genero: 'PREFIERO_NO_DECIRLO',
        estado: true,
      });
      await this.userRepository.save(dama);
    }

    // 6. Crear Categorías, Productos y Variantes del Menú del Bar
    // Solo crear si no existen productos
    const productCount = await this.productRepository.count({ where: { bar_id: bar.id } });
    if (productCount === 0) {
      // Eliminar categorías existentes por si acaso (si no hay productos)
      await this.categoryRepository.delete({ bar_id: bar.id });

      // Tragos & Cócteles
      const catTragos = await this.categoryRepository.save(
        this.categoryRepository.create({
          bar_id: bar.id,
          nombre: 'Tragos & Cócteles',
          orden: 1,
        }),
      );

      // Cervezas
      const catCervezas = await this.categoryRepository.save(
        this.categoryRepository.create({
          bar_id: bar.id,
          nombre: 'Cervezas',
          orden: 2,
        }),
      );

      // Bebidas Analcohólicas
      const catSuaves = await this.categoryRepository.save(
        this.categoryRepository.create({
          bar_id: bar.id,
          nombre: 'Bebidas Analcohólicas',
          orden: 3,
        }),
      );

      // Estructurar productos y sus variantes (TypeORM persistirá variantes en cascada)
      const productosData = [
        {
          bar_id: bar.id,
          categoria_id: catTragos.id,
          nombre: 'Fernet Branca',
          descripcion: 'Clásico fernet cordobés servido con Coca Cola y abundante hielo.',
          foto_url: 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=500',
          variantes: [
            { 
              nombre: 'Vaso Simple', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 30.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 55.0 }
              ] 
            },
            { 
              nombre: 'Jarra 1L', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 75.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 120.0 }
              ] 
            },
          ],
        },
        {
          bar_id: bar.id,
          categoria_id: catTragos.id,
          nombre: 'Whisky Red Label',
          descripcion: 'Johnnie Walker Etiqueta Roja en las rocas o puro.',
          foto_url: 'https://images.unsplash.com/photo-1514218240783-940066a4b6c7?w=500',
          variantes: [
            { 
              nombre: 'Medida en Vaso', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 35.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 60.0 }
              ]
            },
            { 
              nombre: 'Botella 750ml', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 380.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 550.0 }
              ]
            },
          ],
        },
        {
          bar_id: bar.id,
          categoria_id: catTragos.id,
          nombre: 'Mojito Cubano',
          descripcion: 'Ron blanco, menta fresca del huerto, limón natural y soda.',
          foto_url: 'https://images.unsplash.com/photo-1575037614876-c38a4d44f5b8?w=500',
          variantes: [
            { 
              nombre: 'Copa Estándar', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 25.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 50.0 }
              ]
            },
          ],
        },
        {
          bar_id: bar.id,
          categoria_id: catCervezas.id,
          nombre: 'Corona Extra 355ml',
          descripcion: 'Cerveza mexicana tipo lager ligera, con rodaja de limón.',
          foto_url: 'https://images.unsplash.com/photo-1600788886242-5c96aabe3757?w=500',
          variantes: [
            { 
              nombre: 'Botella Fria', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 20.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 40.0 }
              ]
            },
            { 
              nombre: 'Balde x 5 unidades', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 90.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 180.0 }
              ]
            },
          ],
        },
        {
          bar_id: bar.id,
          categoria_id: catCervezas.id,
          nombre: 'Paceña Centenario 620ml',
          descripcion: 'Cerveza Pilsner boliviana de alta calidad y sabor robusto.',
          foto_url: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500',
          variantes: [
            { 
              nombre: 'Botella Grande', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 18.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 35.0 }
              ]
            },
          ],
        },
        {
          bar_id: bar.id,
          categoria_id: catSuaves.id,
          nombre: 'Red Bull Energy Drink',
          descripcion: 'Bebida energética que te da alas en lata personal.',
          foto_url: 'https://images.unsplash.com/photo-1622543929424-71d57b282928?w=500',
          variantes: [
            { 
              nombre: 'Lata 250ml', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 25.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 45.0 }
              ]
            },
          ],
        },
        {
          bar_id: bar.id,
          categoria_id: catSuaves.id,
          nombre: 'Coca Cola Personal',
          descripcion: 'Refresco clásico personal en envase de vidrio.',
          foto_url: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500',
          variantes: [
            { 
              nombre: 'Vidrio 350ml', 
              precios: [
                { tarifa_id: tarifaGeneral.id, precio_unitario: 10.0 },
                { tarifa_id: companiaTarifaId, precio_unitario: 20.0 }
              ]
            },
          ],
        },
      ];

      for (const p of productosData) {
        await this.productRepository.save(this.productRepository.create(p));
      }
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
