import { IsNumber, Min } from 'class-validator';

export class AperturaCajaDto {
  @IsNumber({ maxDecimalPlaces: 2 }, { message: 'El monto inicial debe ser un número válido' })
  @Min(0, { message: 'El monto inicial no puede ser negativo' })
  monto_inicial: number;
}
