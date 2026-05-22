import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToMany, UpdateDateColumn } from 'typeorm';
import { Bar } from '../../bars/entities/bar.entity';
import { Product } from '../../products/entities/product.entity';

@Entity('categorias')
export class Category {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  bar_id: string;

  @ManyToOne(() => Bar, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'bar_id' })
  bar: Bar;

  @Column()
  nombre: string;

  @Column({ default: 0 })
  orden: number;

  @OneToMany(() => Product, (product) => product.categoria)
  productos: Product[];

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
