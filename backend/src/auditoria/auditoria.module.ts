import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuditoriaService } from './auditoria.service';
import { AuditoriaController } from './auditoria.controller';
import { Auditoria } from './entities/auditoria.entity';
import { RolesModule } from '../roles/roles.module';

@Global()
@Module({
  imports: [
    TypeOrmModule.forFeature([Auditoria]),
    RolesModule,
  ],
  controllers: [AuditoriaController],
  providers: [AuditoriaService],
  exports: [AuditoriaService],
})
export class AuditoriaModule {}
