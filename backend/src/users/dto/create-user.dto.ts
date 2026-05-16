import { IsString, IsNotEmpty, IsOptional, IsBoolean, IsUUID } from 'class-validator';

export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  username: string;

  @IsString()
  @IsNotEmpty()
  password?: string;

  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsNotEmpty()
  apellido: string;

  @IsUUID()
  @IsNotEmpty()
  rol_id: string;

  @IsUUID()
  @IsOptional()
  bar_id?: string;

  @IsString()
  @IsOptional()
  foto_url?: string;

  @IsString()
  @IsOptional()
  identificacion?: string;

  @IsString()
  @IsOptional()
  nacionalidad?: string;

  @IsString()
  @IsOptional()
  celular?: string;

  @IsString()
  @IsOptional()
  direccion?: string;
}
