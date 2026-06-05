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
    barId: string | null;
    usuarioId: string | null;
    rolNombre: string;
    accion: string;
    modulo: string;
    detalles: any;
    ipAddress?: string;
    userAgent?: string;
  }): Promise<Auditoria> {
    const dispositivoParsed = this.parseUserAgent(logData.userAgent);

    const log = this.auditoriaRepository.create({
      bar_id: logData.barId,
      usuario_id: logData.usuarioId,
      rol_nombre: logData.rolNombre,
      accion: logData.accion,
      modulo: logData.modulo,
      detalles: logData.detalles,
      ip_address: logData.ipAddress || null,
      dispositivo: dispositivoParsed,
    });

    return await this.auditoriaRepository.save(log);
  }

  private parseUserAgent(userAgent: string | undefined): string | null {
    if (!userAgent) return null;

    const ua = userAgent.toLowerCase();
    let os = 'Desconocido';
    let browser = 'Desconocido';
    let device = 'Web';

    // Detectar OS / Dispositivo
    if (ua.includes('ipad')) {
      os = 'iOS';
      device = 'iPad / Tablet';
    } else if (ua.includes('iphone')) {
      os = 'iOS';
      device = 'iPhone';
    } else if (ua.includes('android')) {
      os = 'Android';
      device = ua.includes('mobile') ? 'Móvil' : 'Tablet';
    } else if (ua.includes('windows')) {
      os = 'Windows';
      device = 'Escritorio';
    } else if (ua.includes('macintosh') || ua.includes('mac os')) {
      os = 'macOS';
      device = 'Escritorio';
    } else if (ua.includes('linux')) {
      os = 'Linux';
      device = 'Escritorio';
    }

    // Detectar Navegador / App
    if (ua.includes('gestobarapp')) {
      browser = 'App Gestobar';
    } else if (ua.includes('chrome') || ua.includes('crios')) {
      browser = 'Chrome';
    } else if (ua.includes('safari') && !ua.includes('chrome') && !ua.includes('crios')) {
      browser = 'Safari';
    } else if (ua.includes('firefox') || ua.includes('fxios')) {
      browser = 'Firefox';
    } else if (ua.includes('edge') || ua.includes('edg')) {
      browser = 'Edge';
    } else if (ua.includes('opera') || ua.includes('opr')) {
      browser = 'Opera';
    }

    return `${device} (${os}) - ${browser}`;
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

    const page = query.page ? parseInt(query.page, 10) : 1;
    const limit = query.limit ? parseInt(query.limit, 10) : 20;
    const skip = (page - 1) * limit;

    return await this.auditoriaRepository.find({
      where,
      relations: ['usuario'],
      order: { fecha: 'DESC' },
      take: limit,
      skip: skip,
    });
  }
}
