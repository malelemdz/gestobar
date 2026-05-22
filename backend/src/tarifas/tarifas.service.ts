import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tarifa } from './entities/tarifa.entity';

@Injectable()
export class TarifasService {
  constructor(
    @InjectRepository(Tarifa)
    private readonly tarifaRepository: Repository<Tarifa>,
  ) {}

  async create(bar_id: string, nombre: string, es_default: boolean = false, activo: boolean = true): Promise<Tarifa> {
    if (es_default) {
      await this.tarifaRepository.update({ bar_id, es_default: true }, { es_default: false });
    } else {
      const existingDefault = await this.tarifaRepository.findOne({ where: { bar_id, es_default: true } });
      if (!existingDefault) es_default = true;
    }
    const tarifa = this.tarifaRepository.create({ bar_id, nombre, es_default, activo });
    return await this.tarifaRepository.save(tarifa);
  }

  async findAllByBar(bar_id: string): Promise<Tarifa[]> {
    let tarifas = await this.tarifaRepository.find({ 
      where: { bar_id },
      order: {
        es_default: 'DESC',
        created_at: 'ASC'
      }
    });
    if (tarifas.length === 0) {
      const defaultTarifa = await this.create(bar_id, 'Normal', true, true);
      tarifas = [defaultTarifa];
    }
    return tarifas;
  }

  async findOne(id: string): Promise<Tarifa> {
    const tarifa = await this.tarifaRepository.findOne({ where: { id } });
    if (!tarifa) {
      throw new NotFoundException(`Tarifa con ID ${id} no encontrada`);
    }
    return tarifa;
  }

  async update(id: string, nombre: string, es_default: boolean, activo: boolean): Promise<Tarifa> {
    const tarifa = await this.findOne(id);
    if (es_default && !tarifa.es_default) {
      await this.tarifaRepository.update({ bar_id: tarifa.bar_id, es_default: true }, { es_default: false });
    } else if (!es_default && tarifa.es_default) {
      throw new ConflictException('No puedes quitar la tarifa por defecto. Debes establecer otra tarifa como por defecto.');
    }
    
    if (tarifa.es_default && activo === false) {
      throw new ConflictException('No se puede deshabilitar la tarifa por defecto. Primero establece otra como por defecto.');
    }

    tarifa.nombre = nombre;
    tarifa.es_default = es_default;
    tarifa.activo = activo;
    return await this.tarifaRepository.save(tarifa);
  }

  async remove(id: string): Promise<void> {
    const tarifa = await this.tarifaRepository.findOne({ where: { id }, relations: ['precios'] });
    if (!tarifa) {
      throw new NotFoundException(`Tarifa con ID ${id} no encontrada`);
    }
    if (tarifa.es_default) {
      throw new ConflictException('No se puede eliminar la tarifa por defecto.');
    }
    if (tarifa.precios && tarifa.precios.length > 0) {
      throw new ConflictException('No se puede eliminar la tarifa porque ya tiene precios registrados en los productos.');
    }
    await this.tarifaRepository.remove(tarifa);
  }
}
