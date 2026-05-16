import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Bar } from '../../bars/entities/bar.entity';

@Entity('roles')
export class Role {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  bar_id: string;

  @Column()
  nombre: string;

  @ManyToOne(() => Bar, { nullable: true })
  @JoinColumn({ name: 'bar_id' })
  bar: Bar;
}
