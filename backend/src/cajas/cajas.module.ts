import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CajasService } from './cajas.service';
import { CajasController } from './cajas.controller';
import { Caja } from './entities/caja.entity';
import { CajaMovimiento } from './entities/caja-movimiento.entity';
import { RolesModule } from '../roles/roles.module'; // Required for PermissionsGuard

@Module({
  imports: [
    TypeOrmModule.forFeature([Caja, CajaMovimiento]),
    RolesModule,
  ],
  controllers: [CajasController],
  providers: [CajasService],
  exports: [CajasService],
})
export class CajasModule {}
