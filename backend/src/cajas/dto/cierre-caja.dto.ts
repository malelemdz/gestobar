import { IsNumber, Min } from 'class-validator';

export class CierreCajaDto {
  @IsNumber({ maxDecimalPlaces: 2 }, { message: 'El monto final debe ser un número válido' })
  @Min(0, { message: 'El monto final no puede ser negativo' })
  monto_final: number;
}
