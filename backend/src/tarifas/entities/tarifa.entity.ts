import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn, OneToMany, UpdateDateColumn } from 'typeorm';
import { Bar } from '../../bars/entities/bar.entity';
import { VariantePrecio } from '../../products/entities/variante-precio.entity';

@Entity('tarifas')
export class Tarifa {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  bar_id: string;

  @ManyToOne(() => Bar)
  @JoinColumn({ name: 'bar_id' })
  bar: Bar;

  @Column()
  nombre: string;

  @Column({ default: false })
  es_default: boolean;

  @Column({ default: true })
  activo: boolean;

  @OneToMany(() => VariantePrecio, vp => vp.tarifa)
  precios: VariantePrecio[];

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
