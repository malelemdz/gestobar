import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { VentasService } from './ventas.service';
import { VentasController } from './ventas.controller';
import { VentasGateway } from './ventas.gateway';
import { Venta } from './entities/venta.entity';
import { DetalleVenta } from './entities/detalle-venta.entity';
import { Variant } from '../products/entities/variant.entity';
import { CajasModule } from '../cajas/cajas.module';
import { BarsModule } from '../bars/bars.module';
import { RolesModule } from '../roles/roles.module'; // Required for PermissionsGuard

@Module({
  imports: [
    TypeOrmModule.forFeature([Venta, DetalleVenta, Variant]),
    CajasModule,
    BarsModule,
    RolesModule,
  ],
  controllers: [VentasController],
  providers: [VentasService, VentasGateway],
  exports: [VentasService],
})
export class VentasModule {}
