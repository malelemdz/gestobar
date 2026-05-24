import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async login(loginDto: LoginDto) {
    const user = await this.usersService.findByUsername(loginDto.username);
    if (!user) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (!user.estado) {
      throw new UnauthorizedException('El usuario está deshabilitado. Contacte a su administrador.');
    }

    const isPasswordValid = await bcrypt.compare(loginDto.password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Credenciales inválidas');
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
      },
    };
  }
}
