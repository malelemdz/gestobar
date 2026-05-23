import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, OneToMany, JoinColumn, UpdateDateColumn } from 'typeorm';
import { Bar } from '../../bars/entities/bar.entity';
import { Caja } from '../../cajas/entities/caja.entity';
import { User } from '../../users/entities/user.entity';
import { DetalleVenta } from './detalle-venta.entity';

@Entity('ventas')
export class Venta {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  bar_id: string;

  @ManyToOne(() => Bar)
  @JoinColumn({ name: 'bar_id' })
  bar: Bar;

  @Column({ type: 'uuid' })
  caja_id: string;

  @ManyToOne(() => Caja)
  @JoinColumn({ name: 'caja_id' })
  caja: Caja;

  @Column({ type: 'uuid' })
  usuario_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'usuario_id' })
  usuario: User;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  total: number;

  @Column({ length: 50 })
  metodo_pago: string;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    default: 0,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  monto_efectivo: number;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    default: 0,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  monto_tarjeta: number;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    default: 0,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  monto_tr_qr: number;

  @CreateDateColumn({ type: 'timestamp' })
  fecha: Date;

  @OneToMany(() => DetalleVenta, (detalle) => detalle.venta, { cascade: true })
  detalles: DetalleVenta[];

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
