import { Injectable } from '@nestjs/common';
import { DataSource, EntitySubscriberInterface, InsertEvent, UpdateEvent, RemoveEvent } from 'typeorm';
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
    if (!tableName) return false;
    const excluded = ['auditoria', 'ventas', 'detalle_ventas', 'cajas', 'caja_movimientos', 'rol_permisos'];
    return !excluded.includes(tableName);
  }

  private getModuleName(tableName: string): string {
    const names: Record<string, string> = {
      productos: 'Productos',
      categorias: 'Categorías',
      bares: 'Configuración de Local',
      tarifas: 'Tarifas',
      usuarios: 'Usuarios',
      roles: 'Roles',
      permisos: 'Permisos',
      variantes: 'Variantes',
      variantes_precios: 'Precios',
    };
    return names[tableName] || tableName;
  }

  private getSingularName(tableName: string): { name: string; article: string } {
    const singulars: Record<string, { name: string; article: string }> = {
      productos: { name: 'producto', article: 'el' },
      categorias: { name: 'categoría', article: 'la' },
      bares: { name: 'configuración del local', article: 'la' },
      tarifas: { name: 'tarifa', article: 'la' },
      usuarios: { name: 'usuario', article: 'el' },
      roles: { name: 'rol', article: 'el' },
      permisos: { name: 'permiso', article: 'el' },
      variantes: { name: 'variante', article: 'la' },
      variantes_precios: { name: 'precio', article: 'el' },
    };
    return singulars[tableName] || { name: 'registro', article: 'el' };
  }

  private getEntityDisplayName(entity: any, tableName: string): string {
    if (!entity) return 'Registro';
    if (tableName === 'variantes_precios') {
      return `$${entity.precio_unitario || '0.00'}`;
    }
    return (
      entity.nombre ||
      entity.name ||
      entity.username ||
      entity.concepto ||
      entity.id ||
      'Registro'
    );
  }

  async afterInsert(event: InsertEvent<any>) {
    if (!this.shouldAudit(event.metadata.tableName)) return;
    if (!this.cls.isActive()) return;
    
    const user = this.cls.get('user');
    if (!user) return;

    const modulo = this.getModuleName(event.metadata.tableName);
    const singularInfo = this.getSingularName(event.metadata.tableName);
    const displayName = this.getEntityDisplayName(event.entity, event.metadata.tableName);
    const mensaje = `Creó ${singularInfo.article} ${singularInfo.name}: ${displayName}`;

    const entityId = event.entity?.id;
    const isBarEntity = event.metadata.tableName === 'bares';
    const barId = this.cls.get('barId') || 
                  (isBarEntity ? entityId : null) || 
                  user.barId || 
                  event.entity?.bar_id || 
                  event.entity?.barId || 
                  null;

    await this.auditoriaService.registrar({
      barId,
      usuarioId: user.userId,
      rolNombre: user.rolName || 'Desconocido',
      accion: 'Crear',
      modulo,
      detalles: { mensaje, id: event.entity?.id },
      ipAddress: this.cls.get('ip'),
      userAgent: this.cls.get('userAgent'),
    }, event.manager);
  }

  async afterUpdate(event: UpdateEvent<any>) {
    if (!this.shouldAudit(event.metadata.tableName)) return;
    if (!this.cls.isActive()) return;

    const user = this.cls.get('user');
    if (!user) return;

    const modulo = this.getModuleName(event.metadata.tableName);
    const singularInfo = this.getSingularName(event.metadata.tableName);
    const displayName = this.getEntityDisplayName(event.entity || event.databaseEntity, event.metadata.tableName);
    const mensaje = `Actualizó ${singularInfo.article} ${singularInfo.name}: ${displayName}`;

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

    const entityId = event.entity?.id || event.databaseEntity?.id;
    const isBarEntity = event.metadata.tableName === 'bares';
    const barId = this.cls.get('barId') || 
                  (isBarEntity ? entityId : null) || 
                  user.barId || 
                  event.entity?.bar_id || 
                  event.databaseEntity?.bar_id || 
                  event.entity?.barId || 
                  event.databaseEntity?.barId || 
                  null;

    await this.auditoriaService.registrar({
      barId,
      usuarioId: user.userId,
      rolNombre: user.rolName || 'Desconocido',
      accion: 'Editar',
      modulo,
      detalles: { mensaje, cambios },
      ipAddress: this.cls.get('ip'),
      userAgent: this.cls.get('userAgent'),
    }, event.manager);
  }

  async afterRemove(event: RemoveEvent<any>) {
    if (!this.shouldAudit(event.metadata.tableName)) return;
    if (!this.cls.isActive()) return;

    const user = this.cls.get('user');
    if (!user) return;

    const modulo = this.getModuleName(event.metadata.tableName);
    const singularInfo = this.getSingularName(event.metadata.tableName);
    const displayName = this.getEntityDisplayName(event.databaseEntity, event.metadata.tableName);
    const mensaje = `Eliminó ${singularInfo.article} ${singularInfo.name}: ${displayName}`;

    const entityId = event.databaseEntity?.id;
    const isBarEntity = event.metadata.tableName === 'bares';
    const barId = this.cls.get('barId') || 
                  (isBarEntity ? entityId : null) || 
                  user.barId || 
                  event.databaseEntity?.bar_id || 
                  event.databaseEntity?.barId || 
                  null;

    await this.auditoriaService.registrar({
      barId,
      usuarioId: user.userId,
      rolNombre: user.rolName || 'Desconocido',
      accion: 'Eliminar',
      modulo,
      detalles: { mensaje },
      ipAddress: this.cls.get('ip'),
      userAgent: this.cls.get('userAgent'),
    }, event.manager);
  }
}
