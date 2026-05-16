import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Bar } from './entities/bar.entity';
import { CreateBarDto } from './dto/create-bar.dto';
import { UpdateBarDto } from './dto/update-bar.dto';

@Injectable()
export class BarsService {
  constructor(
    @InjectRepository(Bar)
    private readonly barRepository: Repository<Bar>,
  ) {}

  async create(createBarDto: CreateBarDto): Promise<Bar> {
    const existingBar = await this.barRepository.findOne({ where: { slug: createBarDto.slug } });
    if (existingBar) {
      throw new ConflictException('Un bar con este slug ya existe');
    }
    const bar = this.barRepository.create(createBarDto);
    return await this.barRepository.save(bar);
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
    const bar = await this.findOne(id);
    const updatedBar = this.barRepository.merge(bar, updateBarDto);
    return await this.barRepository.save(updatedBar);
  }

  async remove(id: string): Promise<void> {
    const bar = await this.findOne(id);
    await this.barRepository.remove(bar);
  }
}
