import { IsNumber, Min, IsEnum, IsString, MinLength, IsOptional } from 'class-validator';
import { TipoMovimiento, MetodoPagoMovimiento } from '../entities/caja-movimiento.entity';

export class CreateMovimientoDto {
  @IsNumber({ maxDecimalPlaces: 2 }, { message: 'El monto debe ser un número válido' })
  @Min(0.01, { message: 'El monto del movimiento debe ser mayor a 0' })
  monto: number;

  @IsEnum(TipoMovimiento, { message: 'El tipo de movimiento debe ser INGRESO o EGRESO' })
  tipo: TipoMovimiento;

  @IsEnum(MetodoPagoMovimiento, { message: 'El método de pago debe ser EFECTIVO, TARJETA o TRANSFERENCIA' })
  metodo_pago: MetodoPagoMovimiento;

  @IsString({ message: 'El concepto debe ser texto' })
  @MinLength(3, { message: 'El concepto/motivo debe tener al menos 3 caracteres' })
  concepto: string;

  @IsOptional()
  @IsString()
  created_at?: string;
}
