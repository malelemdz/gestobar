import { IsString, IsNotEmpty, IsBoolean, IsOptional, IsArray, ValidateNested, ArrayMinSize } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateVariantePrecioDto } from './create-variante-precio.dto';
export class CreateVariantDto {
  @IsString()
  @IsNotEmpty({ message: 'El nombre de la variante es obligatorio' })
  nombre: string;

  @IsArray()
  @ArrayMinSize(1, { message: 'Debe proporcionar al menos un precio para la variante' })
  @ValidateNested({ each: true })
  @Type(() => CreateVariantePrecioDto)
  precios: CreateVariantePrecioDto[];

  @IsBoolean()
  @IsOptional()
  disponible?: boolean;
}
