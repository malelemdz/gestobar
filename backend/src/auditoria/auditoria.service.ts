import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThanOrEqual, LessThanOrEqual } from 'typeorm';
import { Auditoria } from './entities/auditoria.entity';
import { QueryAuditoriaDto } from './dto/query-auditoria.dto';

@Injectable()
export class AuditoriaService {
  constructor(
    @InjectRepository(Auditoria)
    private readonly auditoriaRepository: Repository<Auditoria>,
  ) {}

  async registrar(logData: {
    barId: string;
    usuarioId: string;
    rolNombre: string;
    accion: string;
    modulo: string;
    detalles: any;
    ipAddress?: string;
  }): Promise<Auditoria> {
    const log = this.auditoriaRepository.create({
      bar_id: logData.barId,
      usuario_id: logData.usuarioId,
      rol_nombre: logData.rolNombre,
      accion: logData.accion,
      modulo: logData.modulo,
      detalles: logData.detalles,
      ip_address: logData.ipAddress || null,
    });

    return await this.auditoriaRepository.save(log);
  }

  async findAll(barId: string, query: QueryAuditoriaDto): Promise<Auditoria[]> {
    const where: any = { bar_id: barId };

    if (query.usuario_id) {
      where.usuario_id = query.usuario_id;
    }
    if (query.rol_nombre) {
      where.rol_nombre = query.rol_nombre;
    }
    if (query.accion) {
      where.accion = query.accion;
    }
    if (query.modulo) {
      where.modulo = query.modulo;
    }

    if (query.fecha_inicio && query.fecha_fin) {
      where.fecha = Between(new Date(query.fecha_inicio), new Date(query.fecha_fin));
    } else if (query.fecha_inicio) {
      where.fecha = MoreThanOrEqual(new Date(query.fecha_inicio));
    } else if (query.fecha_fin) {
      where.fecha = LessThanOrEqual(new Date(query.fecha_fin));
    }

    return await this.auditoriaRepository.find({
      where,
      relations: ['usuario'],
      order: { fecha: 'DESC' },
    });
  }
}
