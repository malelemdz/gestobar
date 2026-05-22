import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, ManyToMany, JoinTable, UpdateDateColumn } from 'typeorm';
import { Bar } from '../../bars/entities/bar.entity';
import { Permission } from './permission.entity';

@Entity('roles')
export class Role {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', nullable: true })
  bar_id: string | null;

  @Column()
  nombre: string;

  @ManyToOne(() => Bar, { nullable: true })
  @JoinColumn({ name: 'bar_id' })
  bar: Bar;

  @ManyToMany(() => Permission, (permission) => permission.roles)
  @JoinTable({
    name: 'rol_permisos',
    joinColumn: { name: 'rol_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'permiso_id', referencedColumnName: 'id' },
  })
  permisos: Permission[];

  @UpdateDateColumn({ type: 'timestamp' })
  updated_at: Date;
}
