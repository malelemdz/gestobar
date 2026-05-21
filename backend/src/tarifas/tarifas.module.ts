import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TarifasService } from './tarifas.service';
import { TarifasController } from './tarifas.controller';
import { Tarifa } from './entities/tarifa.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Tarifa])],
  controllers: [TarifasController],
  providers: [TarifasService],
  exports: [TarifasService],
})
export class TarifasModule {}
