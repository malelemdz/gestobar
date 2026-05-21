import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SeedService } from './seed.service';
import { SeedController } from './seed.controller';
import { Role } from '../roles/entities/role.entity';
import { Permission } from '../roles/entities/permission.entity';
import { User } from '../users/entities/user.entity';
import { Bar } from '../bars/entities/bar.entity';
import { Category } from '../categories/entities/category.entity';
import { Product } from '../products/entities/product.entity';
import { Tarifa } from '../tarifas/entities/tarifa.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Role, Permission, User, Bar, Category, Product, Tarifa]),
  ],
  controllers: [SeedController],
  providers: [SeedService],
})
export class SeedModule {}
