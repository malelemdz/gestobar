import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { RangoFechasDto } from './dto/rango-fechas.dto';

@Injectable()
export class EstadisticasService {
  constructor(private readonly dataSource: DataSource) {}

  private parseDates(query: RangoFechasDto) {
    // Rango por defecto: últimos 30 días
    const inicio = query.fecha_inicio
      ? new Date(query.fecha_inicio)
      : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const fin = query.fecha_fin ? new Date(query.fecha_fin) : new Date();

    return { inicio, fin };
  }

  async getResumenGeneral(barId: string, query: RangoFechasDto) {
    const { inicio, fin } = this.parseDates(query);

    // 1. Ingresos Totales y Cantidad de Ventas
    const salesResult = await this.dataSource.query(
      `SELECT 
         COALESCE(SUM(total), 0) as total,
         COUNT(*) as cantidad
       FROM ventas 
       WHERE bar_id = $1 AND fecha BETWEEN $2 AND $3`,
      [barId, inicio, fin],
    );

    const ingresosTotales = parseFloat(salesResult[0]?.total || '0');
    const cantidadVentas = parseInt(salesResult[0]?.cantidad || '0');

    // 2. Comisiones Totales pagadas a Damas
    const commissionsResult = await this.dataSource.query(
      `SELECT 
         COALESCE(SUM(dv.comision_dama * dv.cantidad), 0) as total
       FROM detalle_ventas dv
       INNER JOIN ventas v ON dv.venta_id = v.id
       WHERE v.bar_id = $1 AND v.fecha BETWEEN $2 AND $3`,
      [barId, inicio, fin],
    );

    const comisionesTotales = parseFloat(commissionsResult[0]?.total || '0');

    // 3. Desglose por Método de Pago
    const paymentMethods = await this.dataSource.query(
      `SELECT 
         metodo_pago,
         COALESCE(SUM(total), 0) as total,
         COUNT(*) as cantidad
       FROM ventas
       WHERE bar_id = $1 AND fecha BETWEEN $2 AND $3
       GROUP BY metodo_pago
       ORDER BY total DESC`,
      [barId, inicio, fin],
    );

    const desglosePagos = paymentMethods.map((pm: any) => ({
      metodo: pm.metodo_pago,
      total: parseFloat(pm.total || '0'),
      cantidad: parseInt(pm.cantidad || '0'),
    }));

    // 4. Ventas Diarias (para la gráfica de picos)
    const dailySalesResult = await this.dataSource.query(
      `SELECT 
         DATE(fecha) as fecha,
         COALESCE(SUM(total), 0) as total,
         COUNT(*) as cantidad
       FROM ventas 
       WHERE bar_id = $1 AND fecha BETWEEN $2 AND $3
       GROUP BY DATE(fecha)
       ORDER BY DATE(fecha) ASC`,
      [barId, inicio, fin],
    );

    const ventasDiarias = dailySalesResult.map((ds: any) => {
      let fechaStr = '';
      if (ds.fecha instanceof Date) {
        fechaStr = ds.fecha.toISOString().split('T')[0];
      } else if (typeof ds.fecha === 'string') {
        fechaStr = ds.fecha.split('T')[0];
      } else {
        fechaStr = String(ds.fecha);
      }
      return {
        fecha: fechaStr,
        total: parseFloat(ds.total || '0'),
        cantidad: parseInt(ds.cantidad || '0'),
      };
    });

    return {
      rango: {
        inicio,
        fin,
      },
      ingresos_totales: ingresosTotales,
      comisiones_pagadas: comisionesTotales,
      ingreso_neto_estimado: ingresosTotales - comisionesTotales,
      cantidad_ventas: cantidadVentas,
      desglose_pagos: desglosePagos,
      ventas_diarias: ventasDiarias,
    };
  }

  async getRankingProductos(barId: string, query: RangoFechasDto) {
    const { inicio, fin } = this.parseDates(query);

    const rankings = await this.dataSource.query(
      `SELECT 
         var.id as variante_id,
         var.nombre as variante_nombre,
         p.nombre as producto_nombre,
         p.foto_url as producto_foto_url,
         cat.nombre as categoria_nombre,
         SUM(dv.cantidad) as cantidad_vendida,
         SUM(dv.precio_unitario * dv.cantidad) as total_recaudado
       FROM detalle_ventas dv
       INNER JOIN ventas v ON dv.venta_id = v.id
       INNER JOIN variantes var ON dv.variante_id = var.id
       INNER JOIN productos p ON var.producto_id = p.id
       INNER JOIN categorias cat ON p.categoria_id = cat.id
       WHERE v.bar_id = $1 AND v.fecha BETWEEN $2 AND $3
       GROUP BY var.id, var.nombre, p.nombre, p.foto_url, cat.nombre
       ORDER BY cantidad_vendida DESC
       LIMIT 10`,
      [barId, inicio, fin],
    );

    return rankings.map((r: any) => ({
      variante_id: r.variante_id,
      variante_nombre: r.variante_nombre,
      producto_nombre: r.producto_nombre,
      foto_url: r.producto_foto_url,
      categoria: r.categoria_nombre,
      cantidad_vendida: parseInt(r.cantidad_vendida || '0'),
      total_recaudado: parseFloat(r.total_recaudado || '0'),
    }));
  }

  async getRankingDamas(barId: string, query: RangoFechasDto) {
    const { inicio, fin } = this.parseDates(query);

    const rankings = await this.dataSource.query(
      `SELECT 
         u.id as dama_id,
         u.nombre as dama_nombre,
         u.email as dama_email,
         COALESCE(SUM(dv.comision_dama * dv.cantidad), 0) as comisiones_acumuladas,
         COALESCE(SUM(CASE WHEN dv.es_invitacion = true THEN dv.cantidad ELSE 0 END), 0) as invitaciones_recibidas,
         COUNT(DISTINCT v.id) as turnos_compania
       FROM detalle_ventas dv
       INNER JOIN ventas v ON dv.venta_id = v.id
       INNER JOIN usuarios u ON dv.dama_id = u.id
       WHERE v.bar_id = $1 AND v.fecha BETWEEN $2 AND $3
       GROUP BY u.id, u.nombre, u.email
       ORDER BY comisiones_acumuladas DESC
       LIMIT 10`,
      [barId, inicio, fin],
    );

    return rankings.map((r: any) => ({
      dama_id: r.dama_id,
      nombre: r.dama_nombre,
      email: r.dama_email,
      comisiones_acumuladas: parseFloat(r.comisiones_acumuladas || '0'),
      invitaciones_recibidas: parseInt(r.invitaciones_recibidas || '0'),
      turnos_compania: parseInt(r.turnos_compania || '0'),
    }));
  }

  async getStatsPorCaja(barId: string, cajaId: string) {
    // 1. Obtener la sesión de caja
    const cajaResult = await this.dataSource.query(
      `SELECT 
         c.id, c.monto_inicial, c.monto_final, c.fecha_apertura, c.fecha_cierre, c.estado,
         ua.nombre as usuario_apertura, uc.nombre as usuario_cierre
       FROM cajas c
       LEFT JOIN usuarios ua ON c.apertura_usuario_id = ua.id
       LEFT JOIN usuarios uc ON c.cierre_usuario_id = uc.id
       WHERE c.id = $1 AND c.bar_id = $2`,
      [cajaId, barId],
    );

    if (cajaResult.length === 0) {
      return null;
    }

    const c = cajaResult[0];

    // 2. Ingresos Totales de esa Caja
    const salesResult = await this.dataSource.query(
      `SELECT COALESCE(SUM(total), 0) as total, COUNT(*) as cantidad FROM ventas WHERE caja_id = $1`,
      [cajaId],
    );
    const ventasTotales = parseFloat(salesResult[0]?.total || '0');
    const cantidadVentas = parseInt(salesResult[0]?.cantidad || '0');

    // 3. Comisiones Totales pagadas
    const commissionsResult = await this.dataSource.query(
      `SELECT COALESCE(SUM(dv.comision_dama * dv.cantidad), 0) as total 
       FROM detalle_ventas dv
       INNER JOIN ventas v ON dv.venta_id = v.id
       WHERE v.caja_id = $1`,
      [cajaId],
    );
    const comisionesTotales = parseFloat(commissionsResult[0]?.total || '0');

    // 4. Métodos de Pago
    const paymentMethods = await this.dataSource.query(
      `SELECT metodo_pago, COALESCE(SUM(total), 0) as total, COUNT(*) as cantidad 
       FROM ventas WHERE caja_id = $1 GROUP BY metodo_pago`,
      [cajaId],
    );

    const balanceEsperado = parseFloat(c.monto_inicial || '0') + ventasTotales - comisionesTotales;
    const diferencia = c.monto_final !== null ? parseFloat(c.monto_final) - balanceEsperado : null;

    return {
      caja: {
        id: c.id,
        estado: c.estado,
        fecha_apertura: c.fecha_apertura,
        fecha_cierre: c.fecha_cierre,
        usuario_apertura: c.usuario_apertura,
        usuario_cierre: c.usuario_cierre,
        monto_inicial: parseFloat(c.monto_inicial || '0'),
        monto_final: c.monto_final !== null ? parseFloat(c.monto_final) : null,
      },
      ventas: {
        cantidad: cantidadVentas,
        total: ventasTotales,
        comisiones_pagadas: comisionesTotales,
        balance_esperado: balanceEsperado,
        diferencia: diferencia,
      },
      desglose_pagos: paymentMethods.map((pm: any) => ({
        metodo: pm.metodo_pago,
        total: parseFloat(pm.total || '0'),
        cantidad: parseInt(pm.cantidad || '0'),
      })),
    };
  }
}
