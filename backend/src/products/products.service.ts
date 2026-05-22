import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './entities/product.entity';
import { Variant } from './entities/variant.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CreateVariantDto } from './dto/create-variant.dto';
import { UpdateVariantDto } from './dto/update-variant.dto';
import { CategoriesService } from '../categories/categories.service';

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    @InjectRepository(Variant)
    private readonly variantRepository: Repository<Variant>,
    private readonly categoriesService: CategoriesService,
  ) {}

  async create(createProductDto: CreateProductDto, barId: string): Promise<Product> {
    let categoryId = createProductDto.categoria_id;

    if (!categoryId) {
      const defaultCategory = await this.categoriesService.getOrCreateDefaultCategory(barId);
      categoryId = defaultCategory.id;
    } else {
      // Validar que la categoría exista y pertenezca al bar
      await this.categoriesService.findOne(categoryId, barId);
    }

    const product = this.productRepository.create({
      nombre: createProductDto.nombre,
      descripcion: createProductDto.descripcion,
      foto_url: createProductDto.foto_url,
      bar_id: barId,
      categoria_id: categoryId,
      disponible: createProductDto.disponible ?? true,
    });

    // Lógica de variantes: Crear las variantes asociadas (cascada habilitada)
    product.variantes = createProductDto.variantes.map((v) =>
      this.variantRepository.create({
        nombre: v.nombre,
        precios: v.precios.map(p => ({
          tarifa_id: p.tarifa_id,
          precio_unitario: p.precio_unitario,
        })),
        disponible: v.disponible ?? true,
      }),
    );

    return await this.productRepository.save(product);
  }

  async findAll(barId: string, categoryId?: string, isAdmin: boolean = false): Promise<Product[]> {
    const queryBuilder = this.productRepository
      .createQueryBuilder('product')
      .leftJoinAndSelect('product.categoria', 'category')
      .leftJoinAndSelect('product.variantes', 'variant', isAdmin ? '' : 'variant.disponible = :variantDisponible', { variantDisponible: true })
      .leftJoinAndSelect('variant.precios', 'precio')
      .leftJoinAndSelect('precio.tarifa', 'tarifa')
      .where('product.bar_id = :barId', { barId });

    if (!isAdmin) {
      queryBuilder.andWhere('product.disponible = :disponible', { disponible: true });
    }

    if (categoryId) {
      queryBuilder.andWhere('product.categoria_id = :categoryId', { categoryId });
    }

    return await queryBuilder.getMany();
  }

  async findOne(id: string, barId: string): Promise<Product> {
    const product = await this.productRepository.findOne({
      where: { id, bar_id: barId },
      relations: ['categoria', 'variantes', 'variantes.precios'],
    });

    if (!product) {
      throw new NotFoundException(`Producto con ID ${id} no encontrado en este bar`);
    }

    return product;
  }

  async update(id: string, updateProductDto: UpdateProductDto, barId: string): Promise<Product> {
    const product = await this.findOne(id, barId);

    if (updateProductDto.categoria_id) {
      // Validar que la categoría pertenezca al bar
      await this.categoriesService.findOne(updateProductDto.categoria_id, barId);
      product.categoria_id = updateProductDto.categoria_id;
    }

    if (updateProductDto.nombre !== undefined) product.nombre = updateProductDto.nombre;
    if (updateProductDto.descripcion !== undefined) product.descripcion = updateProductDto.descripcion;
    if (updateProductDto.foto_url !== undefined) product.foto_url = updateProductDto.foto_url;
    if (updateProductDto.disponible !== undefined) product.disponible = updateProductDto.disponible;

    await this.productRepository.save(product);

    // Cascada de disponibilidad hacia las variantes
    if (updateProductDto.disponible !== undefined) {
      await this.productRepository.manager.query(
        `UPDATE variantes SET disponible = $1 WHERE producto_id = $2`,
        [updateProductDto.disponible, id]
      );
    }

    return product;
  }

  async remove(id: string, barId: string): Promise<void> {
    const product = await this.findOne(id, barId);
    await this.productRepository.remove(product);
  }

  // --- MÉTODOS ADICIONALES PARA LA GESTIÓN DE VARIANTES ---

  async addVariant(productId: string, createVariantDto: CreateVariantDto, barId: string): Promise<Variant> {
    // Validar propiedad del producto
    await this.findOne(productId, barId);

    const variant = this.variantRepository.create({
      nombre: createVariantDto.nombre,
      producto_id: productId,
      disponible: createVariantDto.disponible ?? true,
      precios: createVariantDto.precios.map(p => ({
        tarifa_id: p.tarifa_id,
        precio_unitario: p.precio_unitario,
      })),
    });

    return await this.variantRepository.save(variant);
  }

  async updateVariant(variantId: string, updateVariantDto: UpdateVariantDto, barId: string): Promise<Variant> {
    // Validar propiedad de la variante buscando su producto asociado
    const variant = await this.variantRepository.findOne({
      where: { id: variantId },
      relations: ['producto'],
    });

    if (!variant || variant.producto.bar_id !== barId) {
      throw new NotFoundException(`Variante con ID ${variantId} no encontrada`);
    }

    const updated = this.variantRepository.merge(variant, updateVariantDto);
    return await this.variantRepository.save(updated);
  }

  async removeVariant(variantId: string, barId: string): Promise<void> {
    // Validar propiedad de la variante buscando su producto asociado
    const variant = await this.variantRepository.findOne({
      where: { id: variantId },
      relations: ['producto'],
    });

    if (!variant || variant.producto.bar_id !== barId) {
      throw new NotFoundException(`Variante con ID ${variantId} no encontrada`);
    }

    // Negocio: Todo producto tiene al menos una variante.
    // Validamos cuántas variantes tiene el producto actualmente.
    const totalVariants = await this.variantRepository.count({
      where: { producto_id: variant.producto_id },
    });

    if (totalVariants <= 1) {
      throw new BadRequestException('No puedes eliminar la última variante. Todo producto debe tener al menos una variante.');
    }

    await this.variantRepository.remove(variant);
  }
}
