import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Bar } from '../../bars/entities/bar.entity';
import { User } from '../../users/entities/user.entity';

@Entity('auditoria')
export class Auditoria {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  bar_id: string;

  @ManyToOne(() => Bar, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'bar_id' })
  bar: Bar;

  @Column({ type: 'uuid' })
  usuario_id: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'usuario_id' })
  usuario: User;

  @Column({ length: 50 })
  rol_nombre: string;

  @Column({ length: 100 })
  accion: string;

  @Column({ length: 50 })
  modulo: string;

  @Column({ type: 'jsonb', nullable: true })
  detalles: any;

  @Column({ type: 'varchar', length: 45, nullable: true })
  ip_address: string | null;

  @Column({ type: 'varchar', length: 150, nullable: true })
  dispositivo: string | null;

  @CreateDateColumn({ type: 'timestamp' })
  fecha: Date;
}
