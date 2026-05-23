import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn } from 'typeorm';
import { Caja } from './caja.entity';
import { User } from '../../users/entities/user.entity';

export enum TipoMovimiento {
  INGRESO = 'INGRESO',
  EGRESO = 'EGRESO',
}

export enum MetodoPagoMovimiento {
  EFECTIVO = 'EFECTIVO',
  TARJETA = 'TARJETA',
  TRANSFERENCIA = 'TRANSFERENCIA',
}

@Entity('caja_movimientos')
export class CajaMovimiento {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  caja_id: string;

  @ManyToOne(() => Caja, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'caja_id' })
  caja: Caja;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  monto: number;

  @Column({
    type: 'enum',
    enum: TipoMovimiento,
  })
  tipo: TipoMovimiento;

  @Column({
    type: 'enum',
    enum: MetodoPagoMovimiento,
    default: MetodoPagoMovimiento.EFECTIVO,
  })
  metodo_pago: MetodoPagoMovimiento;

  @Column({ type: 'text' })
  concepto: string;

  @Column({ type: 'uuid' })
  usuario_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'usuario_id' })
  usuario: User;

  @CreateDateColumn({ type: 'timestamp' })
  created_at: Date;
}
