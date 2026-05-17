import { IsString, IsNotEmpty, IsOptional, IsUUID, IsArray, ValidateNested, ArrayMinSize } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateVariantDto } from './create-variant.dto';

export class CreateProductDto {
  @IsString()
  @IsNotEmpty({ message: 'El nombre del producto es obligatorio' })
  nombre: string;

  @IsString()
  @IsOptional()
  descripcion?: string;

  @IsString()
  @IsOptional()
  foto_url?: string;

  @IsUUID('4', { message: 'El ID de categoría debe ser un UUID válido' })
  @IsOptional()
  categoria_id?: string;

  @IsArray()
  @ArrayMinSize(1, { message: 'El producto debe tener al menos una variante' })
  @ValidateNested({ each: true })
  @Type(() => CreateVariantDto)
  variantes: CreateVariantDto[];
}
