import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, UpdateDateColumn } from 'typeorm';
import { Variant } from './variant.entity';
import { Tarifa } from '../../tarifas/entities/tarifa.entity';

@Entity('variantes_precios')
export class VariantePrecio {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  variante_id: string;

  @ManyToOne(() => Variant, v => v.precios, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'variante_id' })
  variante: Variant;

  @Column({ type: 'uuid' })
  tarifa_id: string;

  @ManyToOne(() => Tarifa, t => t.precios, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tarifa_id' })
  tarifa: Tarifa;

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

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
