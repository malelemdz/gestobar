import { Entity, PrimaryGeneratedColumn, Column, ManyToMany } from 'typeorm';
import { Role } from '../../roles/entities/role.entity';

@Entity('permisos')
export class Permission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  nombre: string; // Ej: 'ventas.crear', 'productos.gestionar'

  @ManyToMany(() => Role, (role) => role.permisos)
  roles: Role[];
}
