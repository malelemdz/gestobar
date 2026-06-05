import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Caja, EstadoCaja } from './entities/caja.entity';
import { CajaMovimiento, TipoMovimiento } from './entities/caja-movimiento.entity';
import { AperturaCajaDto } from './dto/apertura-caja.dto';
import { CierreCajaDto } from './dto/cierre-caja.dto';
import { CreateMovimientoDto } from './dto/create-movimiento.dto';
import { AuditoriaService } from '../auditoria/auditoria.service';
import { UserPayload } from '../auth/decorators/active-user.decorator';
import { SocketGateway } from '../socket/socket.gateway';

@Injectable()
export class CajasService {
  constructor(
    @InjectRepository(Caja)
    private readonly cajaRepository: Repository<Caja>,
    @InjectRepository(CajaMovimiento)
    private readonly movimientoRepository: Repository<CajaMovimiento>,
    private readonly dataSource: DataSource,
    private readonly auditoriaService: AuditoriaService,
    private readonly socketGateway: SocketGateway,
  ) {}

  async getActiveCaja(barId: string): Promise<Caja> {
    const active = await this.cajaRepository.findOne({
      where: { bar_id: barId, estado: EstadoCaja.ABIERTA },
    });
    if (!active) {
      throw new BadRequestException('No hay ninguna caja abierta en este bar. Operación denegada.');
    }
    return active;
  }

  async getEstado(barId: string): Promise<any> {
    const active = await this.cajaRepository.findOne({
      where: { bar_id: barId, estado: EstadoCaja.ABIERTA },
      relations: ['aperturaUsuario'],
    });

    if (!active) {
      return {
        abierta: false,
        caja: null,
      };
    }

    // 1. Obtener agregaciones de ventas POS por canal de pago
    let totalVentasEfectivo = 0;
    let totalVentasTarjeta = 0;
    let totalVentasTrQr = 0;
    let totalComisionesDamas = 0;

    try {
      const salesResult = await this.dataSource.query(
        `SELECT 
          COALESCE(SUM(monto_efectivo), 0) as efectivo,
          COALESCE(SUM(monto_tarjeta), 0) as tarjeta,
          COALESCE(SUM(monto_tr_qr), 0) as tr_qr
         FROM ventas WHERE caja_id = $1`,
        [active.id],
      );
      totalVentasEfectivo = parseFloat(salesResult[0]?.efectivo || '0');
      totalVentasTarjeta = parseFloat(salesResult[0]?.tarjeta || '0');
      totalVentasTrQr = parseFloat(salesResult[0]?.tr_qr || '0');

      const comResult = await this.dataSource.query(
        `SELECT COALESCE(SUM(dv.comision_dama * dv.cantidad), 0) as total 
         FROM detalle_ventas dv 
         INNER JOIN ventas v ON dv.venta_id = v.id 
         WHERE v.caja_id = $1`,
        [active.id],
      );
      totalComisionesDamas = parseFloat(comResult[0]?.total || '0');
    } catch (e) {
      // Las tablas ventas o detalle_ventas no existen aún.
    }

    // 2. Obtener agregaciones de caja chica manual (ingresos y egresos)
    let totalIngresosManuales = 0;
    let totalEgresosManuales = 0;
    let movimientos: CajaMovimiento[] = [];

    try {
      movimientos = await this.movimientoRepository.find({
        where: { caja_id: active.id },
        relations: ['usuario'],
        order: { created_at: 'DESC' },
      });

      totalIngresosManuales = movimientos
        .filter((m) => m.tipo === TipoMovimiento.INGRESO)
        .reduce((sum, m) => sum + Number(m.monto), 0);

      totalEgresosManuales = movimientos
        .filter((m) => m.tipo === TipoMovimiento.EGRESO)
        .reduce((sum, m) => sum + Number(m.monto), 0);
    } catch (e) {
      // Error o tabla vacía
    }

    const totalVentasPOS = totalVentasEfectivo + totalVentasTarjeta + totalVentasTrQr;

    // 3. FÓRMULAS FINANCIERAS SEGREGADAS A PRUEBA DE CONTAMINACIÓN
    // Total Esperado en Gaveta = Fondo Inicial + Ventas Totales POS + Ingresos Manuales - Egresos Manuales
    const totalEsperadoGaveta = active.monto_inicial + totalVentasPOS + totalIngresosManuales - totalEgresosManuales;

    // Ganancia Neta del Bar = Ventas Totales POS - Comisiones Damas - Egresos Manuales
    const gananciaNetaBar = totalVentasPOS - totalComisionesDamas - totalEgresosManuales;

    return {
      abierta: true,
      caja: {
        ...active,
        total_ventas_efectivo: totalVentasEfectivo,
        total_ventas_tarjeta: totalVentasTarjeta,
        total_ventas_tr_qr: totalVentasTrQr,
        total_ingresos_manuales: totalIngresosManuales,
        total_egresos_manuales: totalEgresosManuales,
        total_comisiones_damas: totalComisionesDamas,
        total_esperado_gaveta: totalEsperadoGaveta,
        ganancia_neta_bar: gananciaNetaBar,
        movimientos,
      },
    };
  }

  async apertura(
    aperturaCajaDto: AperturaCajaDto,
    barId: string,
    user: UserPayload,
    ipAndUa?: { ipAddress?: string; userAgent?: string },
  ): Promise<Caja> {
    // Verificar si ya existe una caja abierta para este bar
    const activeState = await this.getEstado(barId);
    if (activeState.abierta) {
      throw new BadRequestException('Ya existe una caja abierta para este bar. Debe cerrarla antes de abrir una nueva.');
    }

    const nuevaCaja = this.cajaRepository.create({
      bar_id: barId,
      apertura_usuario_id: user.userId,
      monto_inicial: aperturaCajaDto.monto_inicial,
      estado: EstadoCaja.ABIERTA,
    });

    const savedCaja = await this.cajaRepository.save(nuevaCaja);

    // Registro de Auditoría (Trazabilidad)
    await this.auditoriaService.registrar({
      barId,
      usuarioId: user.userId,
      rolNombre: user.rolName,
      modulo: 'CAJAS',
      accion: 'APERTURA',
      detalles: {
        caja_id: savedCaja.id,
        monto_inicial: savedCaja.monto_inicial,
        mensaje: `Abrió la caja con un monto inicial de $${savedCaja.monto_inicial}`,
      },
      ipAddress: ipAndUa?.ipAddress,
      userAgent: ipAndUa?.userAgent,
    });

    return savedCaja;
  }

  async cierre(
    cierreCajaDto: CierreCajaDto,
    barId: string,
    user: UserPayload,
    ipAndUa?: { ipAddress?: string; userAgent?: string },
  ): Promise<any> {
    // Obtener la caja activa
    const caja = await this.getActiveCaja(barId);

    // Calcular reporte de cierre (Ventas, comisiones y movimientos de caja chica en caliente)
    let ventasTotales = 0;
    let comisionesTotales = 0;
    let totalIngresosManuales = 0;
    let totalEgresosManuales = 0;
    let metodosPago = [];

    try {
      const salesResult = await this.dataSource.query(
        `SELECT SUM(total) as total FROM ventas WHERE caja_id = $1`,
        [caja.id],
      );
      ventasTotales = parseFloat(salesResult[0]?.total || '0');

      const comResult = await this.dataSource.query(
        `SELECT SUM(dv.comision_dama * dv.cantidad) as total 
         FROM detalle_ventas dv 
         INNER JOIN ventas v ON dv.venta_id = v.id 
         WHERE v.caja_id = $1`,
        [caja.id],
      );
      comisionesTotales = parseFloat(comResult[0]?.total || '0');

      const metodosResult = await this.dataSource.query(
        `SELECT metodo_pago, SUM(total) as total, COUNT(*) as cantidad 
         FROM ventas WHERE caja_id = $1 GROUP BY metodo_pago`,
        [caja.id],
      );
      metodosPago = metodosResult.map((r: any) => ({
        metodo: r.metodo_pago,
        total: parseFloat(r.total || '0'),
        amount: parseFloat(r.total || '0'),
        cantidad: parseInt(r.cantidad || '0'),
      }));

      const movs = await this.movimientoRepository.find({
        where: { caja_id: caja.id },
      });
      totalIngresosManuales = movs
        .filter((m) => m.tipo === TipoMovimiento.INGRESO)
        .reduce((sum, m) => sum + Number(m.monto), 0);

      totalEgresosManuales = movs
        .filter((m) => m.tipo === TipoMovimiento.EGRESO)
        .reduce((sum, m) => sum + Number(m.monto), 0);
    } catch (error) {
      //
    }

    // Cierre Autónomo sin Entrada: El monto final se calcula exactamente con el esperado
    const balanceEsperado = caja.monto_inicial + ventasTotales + totalIngresosManuales - totalEgresosManuales;

    caja.cierre_usuario_id = user.userId;
    caja.fecha_cierre = new Date();
    caja.monto_final = balanceEsperado;
    caja.estado = EstadoCaja.CERRADA;

    const savedCaja = await this.cajaRepository.save(caja);

    // Registro de Auditoría (Trazabilidad)
    await this.auditoriaService.registrar({
      barId,
      usuarioId: user.userId,
      rolNombre: user.rolName,
      modulo: 'CAJAS',
      accion: 'CIERRE',
      detalles: {
        caja_id: savedCaja.id,
        monto_inicial: savedCaja.monto_inicial,
        monto_final: savedCaja.monto_final,
        ventas_totales: ventasTotales,
        comisiones_pagadas: comisionesTotales,
        ingresos_manuales: totalIngresosManuales,
        egresos_manuales: totalEgresosManuales,
        balance_esperado: balanceEsperado,
        mensaje: `Cerró la caja. Monto final registrado: $${savedCaja.monto_final}`,
      },
      ipAddress: ipAndUa?.ipAddress,
      userAgent: ipAndUa?.userAgent,
    });

    return {
      mensaje: 'Caja cerrada exitosamente',
      resumen: {
        caja_id: savedCaja.id,
        fecha_apertura: savedCaja.fecha_apertura,
        fecha_cierre: savedCaja.fecha_cierre,
        monto_inicial: savedCaja.monto_inicial,
        monto_final: savedCaja.monto_final,
        ventas_totales: ventasTotales,
        comisiones_pagadas: comisionesTotales,
        ingresos_manuales: totalIngresosManuales,
        egresos_manuales: totalEgresosManuales,
        balance_esperado: balanceEsperado,
        diferencia: 0,
        desglose_pagos: metodosPago,
      },
    };
  }

  async registrarMovimiento(
    createMovimientoDto: CreateMovimientoDto,
    barId: string,
    user: UserPayload,
  ): Promise<CajaMovimiento> {
    const caja = await this.getActiveCaja(barId);
    
    const nuevoMovimiento = this.movimientoRepository.create({
      caja_id: caja.id,
      monto: createMovimientoDto.monto,
      tipo: createMovimientoDto.tipo,
      metodo_pago: createMovimientoDto.metodo_pago,
      concepto: createMovimientoDto.concepto,
      usuario_id: user.userId,
    });

    const savedMov = await this.movimientoRepository.save(nuevoMovimiento);

    await this.auditoriaService.registrar({
      barId,
      usuarioId: user.userId,
      rolNombre: user.rolName,
      modulo: 'CAJAS',
      accion: 'REGISTRAR_MOVIMIENTO',
      detalles: {
        movimiento_id: savedMov.id,
        caja_id: caja.id,
        monto: savedMov.monto,
        tipo: savedMov.tipo,
        metodo_pago: savedMov.metodo_pago,
        concepto: savedMov.concepto,
        mensaje: `${savedMov.tipo === 'INGRESO' ? 'Ingreso' : 'Egreso'} registrado por $${savedMov.monto} con concepto: ${savedMov.concepto}`,
      },
    });

    // Avisar en tiempo real a todos los clientes suscritos al Bar
    this.socketGateway.server.emit(`nuevo_movimiento_bar_${barId}`, savedMov);

    return savedMov;
  }

  async getDamaComisiones(cajaId: string, barId: string): Promise<any[]> {
    const caja = await this.cajaRepository.findOne({
      where: { id: cajaId, bar_id: barId },
    });
    if (!caja) {
      throw new NotFoundException(`Caja con ID ${cajaId} no encontrada.`);
    }

    const query = `
      SELECT 
        u.id as "dama_id", 
        u.nombre as "nombre", 
        u.apellido as "apellido",
        COALESCE(SUM(dv.comision_dama * dv.cantidad), 0) as "total_comision"
      FROM detalle_ventas dv
      INNER JOIN ventas v ON v.id = dv.venta_id
      INNER JOIN usuarios u ON u.id = dv.dama_id
      WHERE v.caja_id = $1
      GROUP BY u.id, u.nombre, u.apellido
    `;

    const result = await this.dataSource.query(query, [cajaId]);

    return result.map((r: any) => ({
      dama_id: r.dama_id,
      nombre: `${r.nombre} ${r.apellido || ''}`.trim(),
      total_comision: parseFloat(r.total_comision || '0'),
    }));
  }

  async findAll(barId: string): Promise<Caja[]> {
    return await this.cajaRepository.find({
      where: { bar_id: barId },
      order: { fecha_apertura: 'DESC' },
      relations: ['aperturaUsuario', 'cierreUsuario'],
    });
  }

  async findOne(id: string, barId: string): Promise<Caja> {
    const caja = await this.cajaRepository.findOne({
      where: { id, bar_id: barId },
      relations: ['aperturaUsuario', 'cierreUsuario'],
    });
    if (!caja) {
      throw new NotFoundException(`Caja con ID ${id} no encontrada`);
    }
    return caja;
  }
}
