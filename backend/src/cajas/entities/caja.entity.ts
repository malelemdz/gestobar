import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Bar } from '../../bars/entities/bar.entity';
import { User } from '../../users/entities/user.entity';

export enum EstadoCaja {
  ABIERTA = 'ABIERTA',
  CERRADA = 'CERRADA',
}

@Entity('cajas')
export class Caja {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  bar_id: string;

  @ManyToOne(() => Bar, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'bar_id' })
  bar: Bar;

  @Column({ type: 'uuid' })
  apertura_usuario_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'apertura_usuario_id' })
  aperturaUsuario: User;

  @Column({ type: 'uuid', nullable: true })
  cierre_usuario_id: string | null;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'cierre_usuario_id' })
  cierreUsuario: User | null;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  fecha_apertura: Date;

  @Column({ type: 'timestamp', nullable: true })
  fecha_cierre: Date | null;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  monto_inicial: number;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    nullable: true,
    transformer: {
      to: (value: number | null) => value,
      from: (value: string | null) => (value ? parseFloat(value) : null),
    },
  })
  monto_final: number | null;

  @Column({
    type: 'enum',
    enum: EstadoCaja,
    default: EstadoCaja.ABIERTA,
  })
  estado: EstadoCaja;
}
