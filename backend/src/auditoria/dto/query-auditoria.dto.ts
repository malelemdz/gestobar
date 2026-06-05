import { IsUUID, IsString, IsOptional, IsDateString } from 'class-validator';

export class QueryAuditoriaDto {
  @IsUUID('4', { message: 'El ID de usuario debe ser un UUID válido' })
  @IsOptional()
  usuario_id?: string;

  @IsString()
  @IsOptional()
  rol_nombre?: string;

  @IsString()
  @IsOptional()
  accion?: string;

  @IsString()
  @IsOptional()
  modulo?: string;

  @IsDateString({}, { message: 'La fecha de inicio debe tener formato de fecha válido (ISO)' })
  @IsOptional()
  fecha_inicio?: string;

  @IsDateString({}, { message: 'La fecha de fin debe tener formato de fecha válido (ISO)' })
  @IsOptional()
  fecha_fin?: string;

  @IsString()
  @IsOptional()
  page?: string;

  @IsString()
  @IsOptional()
  limit?: string;
}
