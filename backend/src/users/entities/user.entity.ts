import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, OneToMany, JoinColumn } from 'typeorm';
import { Role } from '../../roles/entities/role.entity';
import { Bar } from '../../bars/entities/bar.entity';

@Entity('usuarios')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', nullable: true })
  bar_id: string | null;

  @Column({ unique: true })
  username: string;

  @Column({ select: false })
  password: string;

  @Column({ nullable: true })
  foto_url: string;

  @Column()
  nombre: string;

  @Column()
  apellido: string;

  @Column({ nullable: true })
  identificacion: string;

  @Column({ nullable: true })
  nacionalidad: string;

  @Column({ nullable: true })
  celular: string;

  @Column({ nullable: true })
  direccion: string;

  @Column({ default: true })
  estado: boolean;

  @ManyToOne(() => Role)
  @JoinColumn({ name: 'rol_id' })
  rol: Role;

  @Column()
  rol_id: string;

  @OneToMany(() => Bar, (bar) => bar.owner)
  bars: Bar[];

  @CreateDateColumn()
  created_at: Date;
}
