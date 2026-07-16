import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Bar } from './entities/bar.entity';
import { CreateBarDto } from './dto/create-bar.dto';
import { UpdateBarDto } from './dto/update-bar.dto';
import { User } from '../users/entities/user.entity';

@Injectable()
export class BarsService {
  constructor(
    @InjectRepository(Bar)
    private readonly barRepository: Repository<Bar>,
    private readonly dataSource: DataSource,
  ) {}

  async create(createBarDto: CreateBarDto): Promise<Bar> {
    const existingBar = await this.barRepository.findOne({ where: { slug: createBarDto.slug } });
    if (existingBar) {
      throw new ConflictException('Un bar con este slug ya existe');
    }
    const defaultTabs = {
      identidad: true,
      redes: true,
      operaciones: true,
      horario: true,
      compania: true,
      tarifas: true,
    };

    const bar = this.barRepository.create({
      ...createBarDto,
      configuracion_tabs_permitidas: createBarDto.configuracion_tabs_permitidas ?? defaultTabs,
    });
    const savedBar = await this.barRepository.save(bar);

    // Vincular al usuario propietario con el bar creado
    await this.dataSource.manager.update(User, savedBar.owner_id, {
      bar_id: savedBar.id,
    });

    return savedBar;
  }

  async findAll(): Promise<Bar[]> {
    return await this.barRepository.find({ relations: ['owner'] });
  }

  async findOne(id: string): Promise<Bar> {
    const bar = await this.barRepository.findOne({ where: { id }, relations: ['owner'] });
    if (!bar) {
      throw new NotFoundException(`Bar con ID ${id} no encontrado`);
    }
    return bar;
  }

  async update(id: string, updateBarDto: UpdateBarDto): Promise<Bar> {
    const { tasa_conversion, ...rest } = updateBarDto;
    
    console.log('--- INTENTO DE ACTUALIZAR BAR ---');
    console.log('ID:', id);
    console.log('Tasa de Conversion recibida:', tasa_conversion);
    console.log('Resto del DTO:', rest);

    const bar = await this.findOne(id);
    const oldOwnerId = bar.owner_id;
    
    const updatedBar = this.barRepository.merge(bar, rest);
    const savedBar = await this.barRepository.save(updatedBar);

    // Si el propietario cambió, actualizamos los bar_id en los usuarios correspondientes
    if (rest.owner_id && rest.owner_id !== oldOwnerId) {
      await this.dataSource.manager.update(User, oldOwnerId, { bar_id: null });
      await this.dataSource.manager.update(User, rest.owner_id, { bar_id: savedBar.id });
    }

    if (tasa_conversion && tasa_conversion !== 1) {
      console.log('Disparando Query de Multiplicación por:', tasa_conversion);
      
      const resAntes = await this.barRepository.manager.query(
        `SELECT vp.id, vp.precio_unitario FROM variantes_precios vp JOIN variantes v ON vp.variante_id = v.id JOIN productos p ON p.id = v.producto_id WHERE p.bar_id = $1 LIMIT 3`,
        [id]
      );
      console.log('--- PRECIOS ANTES DE LA CONVERSION ---');
      console.table(resAntes);

      const res = await this.barRepository.manager.query(
        `UPDATE variantes_precios vp
         SET precio_unitario = vp.precio_unitario * $1
         FROM variantes v
         JOIN productos p ON p.id = v.producto_id
         WHERE v.id = vp.variante_id AND p.bar_id = $2`,
        [tasa_conversion, id]
      );

      // ¡CRÍTICO! Actualizar las fechas de los productos y variantes para que el celular invalide su caché.
      await this.barRepository.manager.query(
        `UPDATE productos SET updated_at = NOW() WHERE bar_id = $1`,
        [id]
      );
      
      await this.barRepository.manager.query(
        `UPDATE variantes v SET updated_at = NOW() 
         FROM productos p 
         WHERE p.id = v.producto_id AND p.bar_id = $1`,
        [id]
      );
      
      const resDespues = await this.barRepository.manager.query(
        `SELECT vp.id, vp.precio_unitario FROM variantes_precios vp JOIN variantes v ON vp.variante_id = v.id JOIN productos p ON p.id = v.producto_id WHERE p.bar_id = $1 LIMIT 3`,
        [id]
      );
      console.log('--- PRECIOS DESPUES DE LA CONVERSION ---');
      console.table(resDespues);
      console.log('Resultado Query (Filas actualizadas):', res[1] ?? res);
    } else {
      console.log('No se aplicó multiplicación porque la tasa es 1 o undefined');
    }
    
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    const bar = await this.findOne(id);
    await this.barRepository.remove(bar);
  }
}
