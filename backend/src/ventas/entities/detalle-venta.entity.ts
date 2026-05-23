import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, UpdateDateColumn } from 'typeorm';
import { Venta } from './venta.entity';
import { Variant } from '../../products/entities/variant.entity';
import { User } from '../../users/entities/user.entity';
import { Tarifa } from '../../tarifas/entities/tarifa.entity';

@Entity('detalle_ventas')
export class DetalleVenta {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  venta_id: string;

  @ManyToOne(() => Venta, (venta) => venta.detalles, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'venta_id' })
  venta: Venta;

  @Column({ type: 'uuid' })
  variante_id: string;

  @ManyToOne(() => Variant)
  @JoinColumn({ name: 'variante_id' })
  variante: Variant;

  @Column({ type: 'int' })
  cantidad: number;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  precio_unitario: number;

  @Column({ type: 'uuid', nullable: true })
  tarifa_id: string | null;

  @ManyToOne(() => Tarifa, { nullable: true })
  @JoinColumn({ name: 'tarifa_id' })
  tarifa: Tarifa | null;

  @Column({ default: false })
  es_precio_b: boolean;

  @Column({ type: 'uuid', nullable: true })
  dama_id: string | null;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'dama_id' })
  dama: User | null;

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
  comision_dama: number;

  @Column({ default: false })
  es_invitacion: boolean;

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
