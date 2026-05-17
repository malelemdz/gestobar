import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('bares')
export class Bar {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  nombre: string;

  @Column({ nullable: true })
  ciudad: string;

  @Column({ nullable: true })
  direccion: string;

  @Column({ default: 'UTC' })
  timezone: string;

  @Column({ default: 'Bs' })
  moneda_simbolo: string;

  @Column({ default: 'BOB' })
  moneda_iso: string;

  @Column({ nullable: true })
  logo_url: string;

  @Column({ nullable: true })
  whatsapp: string;

  @Column({ nullable: true })
  link_ubicacion: string;

  @Column({ nullable: true })
  facebook: string;

  @Column({ nullable: true })
  instagram: string;

  @Column({ nullable: true })
  tiktok: string;

  @Column({ unique: true })
  slug: string;

  @Column({ default: true })
  estado: boolean;

  @Column({
    type: 'decimal',
    precision: 5,
    scale: 2,
    default: 50.00,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  comision_porcentaje: number;

  @Column()
  owner_id: string;

  @ManyToOne(() => User, (user) => user.bars)
  @JoinColumn({ name: 'owner_id' })
  owner: User;

  @CreateDateColumn()
  created_at: Date;
}
