import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProductsService } from './products.service';
import { ProductsController } from './products.controller';
import { Product } from './entities/product.entity';
import { Variant } from './entities/variant.entity';
import { CategoriesModule } from '../categories/categories.module';
import { RolesModule } from '../roles/roles.module'; // Required for PermissionsGuard

@Module({
  imports: [
    TypeOrmModule.forFeature([Product, Variant]),
    CategoriesModule,
    RolesModule,
  ],
  controllers: [ProductsController],
  providers: [ProductsService],
  exports: [ProductsService],
})
export class ProductsModule {}
