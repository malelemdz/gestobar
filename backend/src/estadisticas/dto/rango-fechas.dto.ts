import { IsOptional, IsDateString } from 'class-validator';

export class RangoFechasDto {
  @IsDateString({}, { message: 'La fecha de inicio debe tener un formato ISO válido' })
  @IsOptional()
  fecha_inicio?: string;

  @IsDateString({}, { message: 'La fecha de fin debe tener un formato ISO válido' })
  @IsOptional()
  fecha_fin?: string;
}
