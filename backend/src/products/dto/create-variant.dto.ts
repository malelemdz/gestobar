import { IsString, IsNotEmpty, IsNumber, Min, IsBoolean, IsOptional } from 'class-validator';

export class CreateVariantDto {
  @IsString()
  @IsNotEmpty({ message: 'El nombre de la variante es obligatorio' })
  nombre: string;

  @IsNumber({ maxDecimalPlaces: 2 }, { message: 'El precio A debe ser un número válido' })
  @Min(0, { message: 'El precio A no puede ser negativo' })
  precio_a: number;

  @IsNumber({ maxDecimalPlaces: 2 }, { message: 'El precio B debe ser un número válido' })
  @Min(0, { message: 'El precio B no puede ser negativo' })
  precio_b: number;

  @IsBoolean()
  @IsOptional()
  disponible?: boolean;
}
