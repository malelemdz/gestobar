import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BarsService } from './bars.service';
import { BarsController } from './bars.controller';
import { Bar } from './entities/bar.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Bar])],
  controllers: [BarsController],
  providers: [BarsService],
  exports: [BarsService],
})
export class BarsModule {}
