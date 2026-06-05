import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Venta } from './entities/venta.entity';
import { DetalleVenta } from './entities/detalle-venta.entity';
import { Variant } from '../products/entities/variant.entity';
import { CajasService } from '../cajas/cajas.service';
import { BarsService } from '../bars/bars.service';
import { SocketGateway } from '../socket/socket.gateway';
import { CreateVentaDto } from './dto/create-venta.dto';
import { AuditoriaService } from '../auditoria/auditoria.service';
import { UserPayload } from '../auth/decorators/active-user.decorator';

@Injectable()
export class VentasService {
  constructor(
    @InjectRepository(Venta)
    private readonly ventaRepository: Repository<Venta>,
    @InjectRepository(DetalleVenta)
    private readonly detalleRepository: Repository<DetalleVenta>,
    @InjectRepository(Variant)
    private readonly variantRepository: Repository<Variant>,
    private readonly cajasService: CajasService,
    private readonly barsService: BarsService,
    private readonly socketGateway: SocketGateway,
    private readonly auditoriaService: AuditoriaService,
  ) {}

  async create(
    createVentaDto: CreateVentaDto,
    barId: string,
    user: UserPayload,
    ipAndUa?: { ipAddress?: string; userAgent?: string },
  ): Promise<Venta> {
    // 1. Bloqueo de ventas si la caja no está abierta (Regla de negocio)
    const activeCaja = await this.cajasService.getActiveCaja(barId);

    // 2. Obtener bar para aplicar el porcentaje de comisión configurable
    const bar = await this.barsService.findOne(barId);
    const comisionPorcentaje = bar.comision_porcentaje;

    let total = 0;
    const detalles: DetalleVenta[] = [];

    // 3. Procesar cada item de la venta
    for (const item of createVentaDto.items) {
      // Obtener la variante y verificar que pertenezca al bar
      const variant = await this.variantRepository.findOne({
        where: { id: item.variante_id },
        relations: ['producto', 'precios', 'precios.tarifa'],
      });

      if (!variant || variant.producto.bar_id !== barId) {
        throw new NotFoundException(`La variante con ID ${item.variante_id} no pertenece a este bar o no existe.`);
      }

      // Validar disponibilidad
      if (!variant.disponible) {
        throw new BadRequestException(`El producto '${variant.producto.nombre} (${variant.nombre})' no está disponible en este momento.`);
      }

      // Buscar el precio de la variante para la tarifa especificada
      const precioTarifa = variant.precios?.find(p => p.tarifa_id === item.tarifa_id);
      if (!precioTarifa) {
        throw new BadRequestException(
          `El producto '${variant.producto.nombre} (${variant.nombre})' no tiene configurado un precio para la tarifa solicitada.`
        );
      }
      
      const precioUnitario = precioTarifa.precio_unitario;
      let comisionDama = 0;

      // Verificar si corresponde a una venta de Compañía (Dama asociada y tarifa_id coincide con bar.tarifa_compania_id)
      const esCompania = item.dama_id && item.tarifa_id === bar.tarifa_compania_id && !item.es_invitacion;

      if (esCompania) {
        // Cálculo de comisión automático y configurable por bar
        const rawComision = precioUnitario * (comisionPorcentaje / 100);
        comisionDama = Math.round(rawComision * 100) / 100; // Redondear a 2 decimales
      } else if (item.es_invitacion) {
        if (!item.dama_id) {
          throw new BadRequestException(`Para registrar una invitación de '${variant.producto.nombre}', debes especificar el 'dama_id'.`);
        }
      }

      const detalle = this.detalleRepository.create({
        variante_id: variant.id,
        cantidad: item.cantidad,
        precio_unitario: precioUnitario,
        tarifa_id: item.tarifa_id,
        es_precio_b: !!esCompania, // Para retrocompatibilidad con reportes viejos
        dama_id: item.dama_id || null,
        comision_dama: comisionDama,
        es_invitacion: item.es_invitacion || false,
      });

      detalles.push(detalle);
      total += precioUnitario * item.cantidad;
    }

    // 4. Determinar desglose de pagos
    let monto_efectivo = 0;
    let monto_tarjeta = 0;
    let monto_tr_qr = 0;

    if (createVentaDto.metodo_pago === 'EFECTIVO') {
      monto_efectivo = total;
    } else if (createVentaDto.metodo_pago === 'TARJETA') {
      monto_tarjeta = total;
    } else if (createVentaDto.metodo_pago === 'TR/QR' || createVentaDto.metodo_pago === 'QR') {
      monto_tr_qr = total;
    } else if (createVentaDto.metodo_pago === 'MIXTO') {
      monto_efectivo = createVentaDto.monto_efectivo || 0;
      monto_tarjeta = createVentaDto.monto_tarjeta || 0;
      monto_tr_qr = createVentaDto.monto_tr_qr || 0;

      const sumaDesglose = monto_efectivo + monto_tarjeta + monto_tr_qr;
      if (Math.abs(sumaDesglose - total) > 0.01) { // Tolerancia por redondeos flotantes
        throw new BadRequestException(`El desglose mixto (${sumaDesglose}) no coincide con el total de la venta (${total}).`);
      }
    }

    // 5. Registrar venta atómica
    const venta = this.ventaRepository.create({
      bar_id: barId,
      caja_id: activeCaja.id,
      usuario_id: user.userId,
      total,
      metodo_pago: createVentaDto.metodo_pago,
      monto_efectivo,
      monto_tarjeta,
      monto_tr_qr,
      detalles,
    });

    const savedVenta = await this.ventaRepository.save(venta);

    // Registro de Auditoría (Trazabilidad)
    await this.auditoriaService.registrar({
      barId,
      usuarioId: user.userId,
      rolNombre: user.rolName,
      modulo: 'VENTAS',
      accion: 'REGISTRAR_VENTA',
      detalles: {
        venta_id: savedVenta.id,
        total: savedVenta.total,
        metodo_pago: savedVenta.metodo_pago,
        cantidad_items: savedVenta.detalles.length,
        mensaje: 'Venta procesada',
      },
      ipAddress: ipAndUa?.ipAddress,
      userAgent: ipAndUa?.userAgent,
    });

    // 5. Notificar en tiempo real por WebSockets a las Damas
    for (const d of savedVenta.detalles) {
      if (d.dama_id) {
        // Volver a buscar el nombre del producto para la notificación
        const variant = await this.variantRepository.findOne({
          where: { id: d.variante_id },
          relations: ['producto'],
        });

        if (variant) {
          this.socketGateway.notificarComision(d.dama_id, {
            tipo: d.es_invitacion ? 'INVITACION' : 'COMISION',
            mensaje: d.es_invitacion
              ? `¡Te han invitado una bebida: ${variant.producto.nombre} (${variant.nombre})!`
              : `¡Nueva comisión de ${d.comision_dama * d.cantidad} ${bar.moneda_simbolo} por la venta de ${variant.producto.nombre}!`,
            detalles: {
              venta_id: savedVenta.id,
              producto: variant.producto.nombre,
              variante: variant.nombre,
              cantidad: d.cantidad,
              comision_unitaria: d.comision_dama,
              comision_total: d.comision_dama * d.cantidad,
              es_invitacion: d.es_invitacion,
              moneda: bar.moneda_simbolo,
            },
          });
        }
      }
    }

    // 6. Sincronización en Tiempo Real: Avisar a todos los Cajeros del Bar
    this.socketGateway.server.emit(`nueva_venta_bar_${barId}`, savedVenta);

    return savedVenta;
  }

  async getActiveVentas(barId: string): Promise<any> {
    const activeCaja = await this.cajasService.getActiveCaja(barId);
    if (!activeCaja) {
      return { totales: { efectivo: 0, tarjeta: 0, tr_qr: 0, general: 0 }, ventas: [] };
    }

    const ventas = await this.ventaRepository.find({
      where: { caja_id: activeCaja.id },
      relations: ['usuario', 'detalles', 'detalles.variante', 'detalles.variante.producto', 'detalles.dama'],
      order: { fecha: 'DESC' },
    });

    const totales = ventas.reduce(
      (acc, v) => {
        acc.efectivo += Number(v.monto_efectivo) || 0;
        acc.tarjeta += Number(v.monto_tarjeta) || 0;
        acc.tr_qr += Number(v.monto_tr_qr) || 0;
        acc.general += Number(v.total) || 0;
        return acc;
      },
      { efectivo: 0, tarjeta: 0, tr_qr: 0, general: 0 }
    );

    return {
      caja_id: activeCaja.id,
      totales,
      ventas,
    };
  }

  async findAll(barId: string): Promise<Venta[]> {
    return await this.ventaRepository.find({
      where: { bar_id: barId },
      relations: ['usuario', 'detalles', 'detalles.variante', 'detalles.variante.producto', 'detalles.dama'],
      order: { fecha: 'DESC' },
    });
  }

  async findOne(id: string, barId: string): Promise<Venta> {
    const venta = await this.ventaRepository.findOne({
      where: { id, bar_id: barId },
      relations: ['usuario', 'detalles', 'detalles.variante', 'detalles.variante.producto', 'detalles.dama'],
    });

    if (!venta) {
      throw new NotFoundException(`Venta con ID ${id} no encontrada`);
    }

    return venta;
  }

  async getDamaComisiones(damaId: string, barId: string): Promise<any> {
    const bar = await this.barsService.findOne(barId);
    
    const detalles = await this.detalleRepository.find({
      where: { dama_id: damaId, venta: { bar_id: barId } },
      relations: ['venta', 'variante', 'variante.producto'],
      order: { venta: { fecha: 'DESC' } },
    });

    const comisionesTotales = detalles.reduce((sum, d) => sum + d.comision_dama * d.cantidad, 0);
    const totalInvitaciones = detalles.filter((d) => d.es_invitacion).reduce((sum, d) => sum + d.cantidad, 0);

    return {
      dama_id: damaId,
      moneda: bar.moneda_simbolo,
      comisiones_totales: comisionesTotales,
      total_invitaciones: totalInvitaciones,
      historial: detalles.map((d) => ({
        detalle_id: d.id,
        fecha: d.venta.fecha,
        producto: d.variante.producto.nombre,
        variante: d.variante.nombre,
        cantidad: d.cantidad,
        es_invitacion: d.es_invitacion,
        es_precio_b: d.es_precio_b,
        precio_cobrado: d.precio_unitario,
        comision_generada: d.comision_dama * d.cantidad,
      })),
    };
  }
}
