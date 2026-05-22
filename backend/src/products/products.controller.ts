import { Controller, Get, Post, Body, Patch, Param, Delete, Query, UseGuards, ParseUUIDPipe } from '@nestjs/common';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CreateVariantDto } from './dto/create-variant.dto';
import { UpdateVariantDto } from './dto/update-variant.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../auth/guards/tenant.guard';
import { PermissionsGuard } from '../auth/guards/permissions.guard';
import { Permissions } from '../auth/decorators/permissions.decorator';
import { ActiveBarId } from '../auth/decorators/active-bar-id.decorator';

@Controller('products')
@UseGuards(JwtAuthGuard, TenantGuard, PermissionsGuard)
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Post()
  @Permissions('productos.gestionar')
  create(@Body() createProductDto: CreateProductDto, @ActiveBarId() barId: string) {
    return this.productsService.create(createProductDto, barId);
  }

  @Get()
  findAll(
    @ActiveBarId() barId: string,
    @Query('categoryId') categoryId?: string,
    @Query('admin') admin?: string,
  ) {
    const isAdmin = admin === 'true';
    return this.productsService.findAll(barId, categoryId, isAdmin);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string, @ActiveBarId() barId: string) {
    return this.productsService.findOne(id, barId);
  }

  @Patch(':id')
  @Permissions('productos.gestionar')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateProductDto: UpdateProductDto,
    @ActiveBarId() barId: string,
  ) {
    return this.productsService.update(id, updateProductDto, barId);
  }

  @Delete(':id')
  @Permissions('productos.gestionar')
  remove(@Param('id', ParseUUIDPipe) id: string, @ActiveBarId() barId: string) {
    return this.productsService.remove(id, barId);
  }

  // --- RUTAS DE GESTIÓN DE VARIANTES ---

  @Post(':id/variants')
  @Permissions('productos.gestionar')
  addVariant(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() createVariantDto: CreateVariantDto,
    @ActiveBarId() barId: string,
  ) {
    return this.productsService.addVariant(id, createVariantDto, barId);
  }

  @Patch('variants/:variantId')
  @Permissions('productos.gestionar')
  updateVariant(
    @Param('variantId', ParseUUIDPipe) variantId: string,
    @Body() updateVariantDto: UpdateVariantDto,
    @ActiveBarId() barId: string,
  ) {
    return this.productsService.updateVariant(variantId, updateVariantDto, barId);
  }

  @Delete('variants/:variantId')
  @Permissions('productos.gestionar')
  removeVariant(
    @Param('variantId', ParseUUIDPipe) variantId: string,
    @ActiveBarId() barId: string,
  ) {
    return this.productsService.removeVariant(variantId, barId);
  }
}
