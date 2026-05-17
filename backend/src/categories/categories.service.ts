import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Category } from './entities/category.entity';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
  ) {}

  async getOrCreateDefaultCategory(barId: string): Promise<Category> {
    const existing = await this.categoryRepository.findOne({
      where: { bar_id: barId, nombre: 'General' },
    });
    if (existing) {
      return existing;
    }

    const defaultCategory = this.categoryRepository.create({
      bar_id: barId,
      nombre: 'General',
      orden: 0,
    });
    return await this.categoryRepository.save(defaultCategory);
  }

  async create(createCategoryDto: CreateCategoryDto, barId: string): Promise<Category> {
    const category = this.categoryRepository.create({
      ...createCategoryDto,
      bar_id: barId,
    });
    return await this.categoryRepository.save(category);
  }

  async findAll(barId: string): Promise<Category[]> {
    let categories = await this.categoryRepository.find({
      where: { bar_id: barId },
      order: { orden: 'ASC', nombre: 'ASC' },
    });

    // Soporte para categoría por defecto si no se crean manualmente
    if (categories.length === 0) {
      const defaultCat = await this.getOrCreateDefaultCategory(barId);
      categories = [defaultCat];
    }

    return categories;
  }

  async findOne(id: string, barId: string): Promise<Category> {
    const category = await this.categoryRepository.findOne({
      where: { id, bar_id: barId },
    });

    if (!category) {
      throw new NotFoundException(`Categoría con ID ${id} no encontrada en este bar`);
    }

    return category;
  }

  async update(id: string, updateCategoryDto: UpdateCategoryDto, barId: string): Promise<Category> {
    const category = await this.findOne(id, barId);
    const updated = this.categoryRepository.merge(category, updateCategoryDto);
    return await this.categoryRepository.save(updated);
  }

  async remove(id: string, barId: string): Promise<void> {
    const category = await this.findOne(id, barId);
    await this.categoryRepository.remove(category);
  }
}
