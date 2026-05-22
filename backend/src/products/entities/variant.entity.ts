import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToMany, UpdateDateColumn } from 'typeorm';
import { Product } from './product.entity';
import { VariantePrecio } from './variante-precio.entity';

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

  @OneToMany(() => VariantePrecio, vp => vp.variante, { cascade: true })
  precios: VariantePrecio[];
  @Column({ default: true })
  disponible: boolean;

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
