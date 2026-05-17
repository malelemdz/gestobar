import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Product } from './product.entity';

@Entity('variantes')
export class Variant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  producto_id: string;

  @ManyToOne(() => Product, (product) => product.variantes, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'producto_id' })
  producto: Product;

  @Column()
  nombre: string;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  precio_a: number;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  precio_b: number;

  @Column({ default: true })
  disponible: boolean;
}
