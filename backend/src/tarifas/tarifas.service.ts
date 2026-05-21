import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tarifa } from './entities/tarifa.entity';

@Injectable()
export class TarifasService {
  constructor(
    @InjectRepository(Tarifa)
    private readonly tarifaRepository: Repository<Tarifa>,
  ) {}

  async create(bar_id: string, nombre: string, es_default: boolean = false): Promise<Tarifa> {
    const tarifa = this.tarifaRepository.create({ bar_id, nombre, es_default });
    return await this.tarifaRepository.save(tarifa);
  }

  async findAllByBar(bar_id: string): Promise<Tarifa[]> {
    return await this.tarifaRepository.find({ where: { bar_id } });
  }

  async findOne(id: string): Promise<Tarifa> {
    const tarifa = await this.tarifaRepository.findOne({ where: { id } });
    if (!tarifa) {
      throw new NotFoundException(`Tarifa con ID ${id} no encontrada`);
    }
    return tarifa;
  }
}
