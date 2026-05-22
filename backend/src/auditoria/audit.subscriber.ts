import { Injectable } from '@nestjs/common';
import { DataSource, EntitySubscriberInterface, InsertEvent, UpdateEvent, RemoveEvent, EventSubscriber } from 'typeorm';
import { ClsService } from 'nestjs-cls';
import { AuditoriaService } from './auditoria.service';

@Injectable()
export class AuditSubscriber implements EntitySubscriberInterface {
  constructor(
    private readonly dataSource: DataSource,
    private readonly cls: ClsService,
    private readonly auditoriaService: AuditoriaService,
  ) {
    this.dataSource.subscribers.push(this);
  }

  private shouldAudit(tableName?: string): boolean {
    return !!tableName && tableName !== 'auditoria';
  }

  private getModuleName(tableName: string): string {
    const names: Record<string, string> = {
      products: 'Productos',
      categories: 'Categorías',
      bars: 'Configuración de Local',
      tarifas: 'Tarifas',
      users: 'Usuarios',
      ventas: 'Ventas',
      detalle_ventas: 'Ventas',
      variantes: 'Variantes',
      variantes_precios: 'Precios',
      cajas: 'Cajas',
      roles: 'Roles'
    };
    return names[tableName] || tableName;
  }

  async afterInsert(event: InsertEvent<any>) {
    if (!this.shouldAudit(event.metadata.tableName)) return;
    if (!this.cls.isActive()) return;
    
    const user = this.cls.get('user');
    if (!user) return;

    const modulo = this.getModuleName(event.metadata.tableName);
    const nombre = event.entity?.nombre || event.entity?.name || event.entity?.id || 'Registro';

    await this.auditoriaService.registrar({
      barId: user.barId,
      usuarioId: user.userId,
      rolNombre: user.rolName || 'Desconocido',
      accion: 'Crear',
      modulo,
      detalles: { mensaje: `Creó un registro: ${nombre}`, id: event.entity?.id },
      ipAddress: this.cls.get('ip'),
      userAgent: this.cls.get('userAgent'),
    });
  }

  async afterUpdate(event: UpdateEvent<any>) {
    if (!this.shouldAudit(event.metadata.tableName)) return;
    if (!this.cls.isActive()) return;

    const user = this.cls.get('user');
    if (!user) return;

    const modulo = this.getModuleName(event.metadata.tableName);
    const nombre = event.entity?.nombre || event.databaseEntity?.nombre || event.databaseEntity?.id || 'Registro';

    const cambios: any = {};
    if (event.databaseEntity && event.entity && event.updatedColumns) {
      const entity = event.entity;
      event.updatedColumns.forEach(col => {
        const prop = col.propertyName;
        if (prop !== 'updated_at' && event.databaseEntity[prop] !== entity[prop]) {
          cambios[prop] = { de: event.databaseEntity[prop], a: entity[prop] };
        }
      });
    }

    if (Object.keys(cambios).length === 0) return;

    await this.auditoriaService.registrar({
      barId: user.barId,
      usuarioId: user.userId,
      rolNombre: user.rolName || 'Desconocido',
      accion: 'Editar',
      modulo,
      detalles: { mensaje: `Actualizó registro: ${nombre}`, cambios },
      ipAddress: this.cls.get('ip'),
      userAgent: this.cls.get('userAgent'),
    });
  }

  async afterRemove(event: RemoveEvent<any>) {
    if (!this.shouldAudit(event.metadata.tableName)) return;
    if (!this.cls.isActive()) return;

    const user = this.cls.get('user');
    if (!user) return;

    const modulo = this.getModuleName(event.metadata.tableName);
    const nombre = event.databaseEntity?.nombre || event.databaseEntity?.id || 'Registro';

    await this.auditoriaService.registrar({
      barId: user.barId,
      usuarioId: user.userId,
      rolNombre: user.rolName || 'Desconocido',
      accion: 'Eliminar',
      modulo,
      detalles: { mensaje: `Eliminó registro: ${nombre}` },
      ipAddress: this.cls.get('ip'),
      userAgent: this.cls.get('userAgent'),
    });
  }
}
