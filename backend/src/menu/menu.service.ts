import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { Bar } from '../bars/entities/bar.entity';
import { Caja, EstadoCaja } from '../cajas/entities/caja.entity';
import { Category } from '../categories/entities/category.entity';
import { Product } from '../products/entities/product.entity';

@Injectable()
export class MenuService {
  constructor(
    @InjectRepository(Bar)
    private readonly barRepository: Repository<Bar>,
    @InjectRepository(Caja)
    private readonly cajaRepository: Repository<Caja>,
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    private readonly configService: ConfigService,
  ) {}

  async getBarProfile(slug: string) {
    const bar = await this.barRepository.findOne({
      where: { slug, estado: true },
    });

    if (!bar) {
      throw new NotFoundException(`Bar con slug '${slug}' no encontrado o inactivo.`);
    }

    // Validación de estado: Mostrar "Cerrado" si la caja no está abierta
    const activeCaja = await this.cajaRepository.findOne({
      where: { bar_id: bar.id, estado: EstadoCaja.ABIERTA },
    });

    const frontendUrl = this.configService.get<string>('FRONTEND_URL') || 'https://gestobar.app';
    const menuUrl = `${frontendUrl}/menu/${bar.slug}`;

    return {
      id: bar.id,
      nombre: bar.nombre,
      ciudad: bar.ciudad,
      direccion: bar.direccion,
      logo_url: bar.logo_url,
      whatsapp: bar.whatsapp,
      link_ubicacion: bar.link_ubicacion,
      facebook: bar.facebook,
      instagram: bar.instagram,
      tiktok: bar.tiktok,
      moneda_simbolo: bar.moneda_simbolo,
      moneda_iso: bar.moneda_iso,
      abierto: !!activeCaja,
      menu_url: menuUrl,
    };
  }

  async getBarCatalog(slug: string) {
    const bar = await this.barRepository.findOne({
      where: { slug, estado: true },
    });

    if (!bar) {
      throw new NotFoundException(`Bar con slug '${slug}' no encontrado o inactivo.`);
    }

    // Obtener las categorías de ese bar
    const categories = await this.categoryRepository.find({
      where: { bar_id: bar.id },
      order: { orden: 'ASC', nombre: 'ASC' },
    });

    // Obtener todos los productos con sus variantes
    const products = await this.productRepository.find({
      where: { bar_id: bar.id },
      relations: ['variantes', 'variantes.precios', 'variantes.precios.tarifa'],
    });

    // Estructurar catálogo sanitizando y protegiendo el Precio B
    return categories.map((cat) => {
      const catProducts = products.filter((p) => p.categoria_id === cat.id);

      return {
        id: cat.id,
        nombre: cat.nombre,
        orden: cat.orden,
        productos: catProducts.map((p) => ({
          id: p.id,
          nombre: p.nombre,
          descripcion: p.descripcion,
          foto_url: p.foto_url,
          // Exponer únicamente variantes disponibles y renombrar precio_a a "precio" (escondiendo precio_b)
          variantes: (p.variantes || [])
            .filter((v) => v.disponible)
            .map((v) => {
              let defaultPrice = 0;
              const defaultTarifa = v.precios?.find(p => p.tarifa?.es_default);
              if (defaultTarifa) {
                defaultPrice = defaultTarifa.precio_unitario;
              } else if (v.precios && v.precios.length > 0) {
                defaultPrice = v.precios[0].precio_unitario;
              }
              
              return {
                id: v.id,
                nombre: v.nombre,
                precio: defaultPrice,
              };
            }),
        })).filter((p) => p.variantes.length > 0), // Solo mostrar productos que tengan variantes disponibles
      };
    }).filter((cat) => cat.productos.length > 0); // Solo mostrar categorías que tengan productos con variantes
  }
}
