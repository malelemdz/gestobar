import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Caja, EstadoCaja } from './entities/caja.entity';
import { AperturaCajaDto } from './dto/apertura-caja.dto';
import { CierreCajaDto } from './dto/cierre-caja.dto';

@Injectable()
export class CajasService {
  constructor(
    @InjectRepository(Caja)
    private readonly cajaRepository: Repository<Caja>,
    private readonly dataSource: DataSource,
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

  async getEstado(barId: string): Promise<{ abierta: boolean; caja: Caja | null }> {
    const active = await this.cajaRepository.findOne({
      where: { bar_id: barId, estado: EstadoCaja.ABIERTA },
    });
    return {
      abierta: !!active,
      caja: active,
    };
  }

  async apertura(aperturaCajaDto: AperturaCajaDto, barId: string, userId: string): Promise<Caja> {
    // Verificar si ya existe una caja abierta para este bar
    const activeState = await this.getEstado(barId);
    if (activeState.abierta) {
      throw new BadRequestException('Ya existe una caja abierta para este bar. Debe cerrarla antes de abrir una nueva.');
    }

    const nuevaCaja = this.cajaRepository.create({
      bar_id: barId,
      apertura_usuario_id: userId,
      monto_inicial: aperturaCajaDto.monto_inicial,
      estado: EstadoCaja.ABIERTA,
    });

    return await this.cajaRepository.save(nuevaCaja);
  }

  async cierre(cierreCajaDto: CierreCajaDto, barId: string, userId: string): Promise<any> {
    // Obtener la caja activa
    const caja = await this.getActiveCaja(barId);

    caja.cierre_usuario_id = userId;
    caja.fecha_cierre = new Date();
    caja.monto_final = cierreCajaDto.monto_final;
    caja.estado = EstadoCaja.CERRADA;

    const savedCaja = await this.cajaRepository.save(caja);

    // Calcular reporte de cierre (Ventas y comisiones vinculadas)
    let ventasTotales = 0;
    let comisionesTotales = 0;
    let metodosPago = [];

    try {
      const salesResult = await this.dataSource.query(
        `SELECT SUM(total) as total FROM ventas WHERE caja_id = $1`,
        [caja.id],
      );
      ventasTotales = parseFloat(salesResult[0]?.total || '0');

      const comResult = await this.dataSource.query(
        `SELECT SUM(dv.comision_dama) as total 
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
        cantidad: parseInt(r.cantidad || '0'),
      }));
    } catch (error) {
      // Las tablas ventas o detalle_ventas no existen aún en base de datos.
      // Se mantiene los valores por defecto (0).
    }

    const balanceEsperado = caja.monto_inicial + ventasTotales - comisionesTotales;
    const diferencia = savedCaja.monto_final! - balanceEsperado;

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
        balance_esperado: balanceEsperado,
        diferencia: diferencia,
        desglose_pagos: metodosPago,
      },
    };
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
