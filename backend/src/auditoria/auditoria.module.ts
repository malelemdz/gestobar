import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuditoriaService } from './auditoria.service';
import { AuditoriaController } from './auditoria.controller';
import { Auditoria } from './entities/auditoria.entity';
import { RolesModule } from '../roles/roles.module';
import { AuditSubscriber } from './audit.subscriber';

@Global()
@Module({
  imports: [
    TypeOrmModule.forFeature([Auditoria]),
    RolesModule,
  ],
  controllers: [AuditoriaController],
  providers: [AuditoriaService, AuditSubscriber],
  exports: [AuditoriaService],
})
export class AuditoriaModule {}
