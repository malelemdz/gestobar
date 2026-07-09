import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../../users/users.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly usersService: UsersService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') || 'default_secret',
    });
  }

  async validate(payload: any) {
    try {
      const user = await this.usersService.findOne(payload.sub);
      if (!user || !user.estado) {
        throw new UnauthorizedException('Usuario no válido o inactivo');
      }
      return {
        userId: payload.sub,
        username: payload.username,
        rolId: payload.rolId,
        rolName: user.rol?.nombre,
        barId: payload.barId,
      };
    } catch (error) {
      throw new UnauthorizedException('Sesión no válida o expirada');
    }
  }
}
