import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, JoinColumn } from 'typeorm';
import { Bar } from '../../bars/entities/bar.entity';
import { Category } from '../../categories/entities/category.entity';
import { Variant } from './variant.entity';

@Entity('productos')
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  bar_id: string;

  @ManyToOne(() => Bar, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'bar_id' })
  bar: Bar;

  @Column({ type: 'uuid' })
  categoria_id: string;

  @ManyToOne(() => Category, (category) => category.productos, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'categoria_id' })
  categoria: Category;

  @Column({ nullable: true })
  foto_url: string;

  @Column()
  nombre: string;

  @Column({ nullable: true })
  descripcion: string;

  @OneToMany(() => Variant, (variant) => variant.producto, { cascade: true })
  variantes: Variant[];
}
