import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto';
import { AuditoriaService } from '../auditoria/auditoria.service';
import { BarsService } from '../bars/bars.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly auditoriaService: AuditoriaService,
    private readonly barsService: BarsService,
  ) {}

  async login(loginDto: LoginDto, ip?: string, userAgent?: string) {
    const user = await this.usersService.findByUsername(loginDto.username);
    if (!user) {
      await this.auditoriaService.registrar({
        barId: null,
        usuarioId: null,
        rolNombre: 'INVITADO',
        modulo: 'Sesión',
        accion: 'Inicio de Sesión Fallido',
        detalles: { mensaje: `Intento fallido de inicio de sesión. Usuario no encontrado: ${loginDto.username}` },
        ipAddress: ip,
        userAgent: userAgent,
      }).catch(() => {});
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (user.bar_id) {
      const bar = await this.barsService.findOne(user.bar_id);
      if (bar && !bar.estado) {
        if (user.rol?.nombre !== 'ADMIN' && user.rol?.nombre !== 'SUPERADMIN') {
          await this.auditoriaService.registrar({
            barId: user.bar_id,
            usuarioId: user.id,
            rolNombre: user.rol?.nombre || 'STAFF',
            modulo: 'Sesión',
            accion: 'Inicio de Sesión Fallido',
            detalles: { mensaje: `Intento de inicio de sesión fallido en Bar inactivo: ${bar.nombre}` },
            ipAddress: ip,
            userAgent: userAgent,
          }).catch(() => {});
          throw new UnauthorizedException('Este local está inactivo por falta de pago. Contacte a soporte.');
        }
      }
    }

    if (!user.estado) {
      await this.auditoriaService.registrar({
        barId: user.bar_id,
        usuarioId: user.id,
        rolNombre: user.rol?.nombre || 'STAFF',
        modulo: 'Sesión',
        accion: 'Inicio de Sesión Fallido',
        detalles: { mensaje: `Intento fallido de inicio de sesión. Usuario deshabilitado: ${user.username}` },
        ipAddress: ip,
        userAgent: userAgent,
      }).catch(() => {});
      throw new UnauthorizedException('El usuario está deshabilitado. Contacte a su administrador.');
    }

    const isPasswordValid = await bcrypt.compare(loginDto.password, user.password);
    if (!isPasswordValid) {
      await this.auditoriaService.registrar({
        barId: user.bar_id,
        usuarioId: user.id,
        rolNombre: user.rol?.nombre || 'STAFF',
        modulo: 'Sesión',
        accion: 'Inicio de Sesión Fallido',
        detalles: { mensaje: `Intento fallido de inicio de sesión. Contraseña incorrecta para el usuario: ${user.username}` },
        ipAddress: ip,
        userAgent: userAgent,
      }).catch(() => {});
      throw new UnauthorizedException('Credenciales inválidas');
    }

    // Success log
    await this.auditoriaService.registrar({
      barId: user.bar_id,
      usuarioId: user.id,
      rolNombre: user.rol?.nombre || 'STAFF',
      modulo: 'Sesión',
      accion: 'Inicio de Sesión',
      detalles: { mensaje: `El usuario ${user.username} inició sesión correctamente.` },
      ipAddress: ip,
      userAgent: userAgent,
    }).catch(() => {});

    const payload = {
      username: user.username,
      sub: user.id,
      rolId: user.rol_id,
      barId: user.bar_id,
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        username: user.username,
        rol_id: user.rol_id,
        bar_id: user.bar_id,
        nombre: user.nombre,
        rol_nombre: user.rol?.nombre || 'STAFF',
        foto_url: user.foto_url,
        celular: user.celular,
        permisos: user.rol?.permisos?.map(p => p.nombre) || [],
      },
    };
  }

  async renewToken(userPayload: any, ip?: string, userAgent?: string) {
    const user = await this.usersService.findOne(userPayload.userId);
    if (!user || !user.estado) {
      throw new UnauthorizedException('Usuario no válido o inactivo');
    }

    if (user.bar_id) {
      const bar = await this.barsService.findOne(user.bar_id);
      if (bar && !bar.estado) {
        if (user.rol?.nombre !== 'ADMIN' && user.rol?.nombre !== 'SUPERADMIN') {
          throw new UnauthorizedException('Este local está inactivo por falta de pago. Contacte a soporte.');
        }
      }
    }

    const payload = {
      username: user.username,
      sub: user.id,
      rolId: user.rol_id,
      barId: user.bar_id,
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        username: user.username,
        rol_id: user.rol_id,
        bar_id: user.bar_id,
        nombre: user.nombre,
        rol_nombre: user.rol?.nombre || 'STAFF',
        foto_url: user.foto_url,
        celular: user.celular,
        permisos: user.rol?.permisos?.map(p => p.nombre) || [],
      },
    };
  }
}
