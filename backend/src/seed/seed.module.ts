import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SeedService } from './seed.service';
import { SeedController } from './seed.controller';
import { Role } from '../roles/entities/role.entity';
import { Permission } from '../roles/entities/permission.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Role, Permission])],
  controllers: [SeedController],
  providers: [SeedService],
})
export class SeedModule {}
