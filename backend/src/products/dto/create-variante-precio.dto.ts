import { IsNotEmpty, IsNumber, IsUUID, Min } from 'class-validator';

export class CreateVariantePrecioDto {
  @IsUUID('4', { message: 'El ID de tarifa debe ser un UUID válido' })
  @IsNotEmpty()
  tarifa_id: string;

  @IsNumber({ maxDecimalPlaces: 2 }, { message: 'El precio debe ser un número válido' })
  @Min(0, { message: 'El precio no puede ser negativo' })
  precio_unitario: number;
}
