import { IsString, IsOptional, IsUUID, IsBoolean } from 'class-validator';

export class UpdateProductDto {
  @IsString()
  @IsOptional()
  nombre?: string;

  @IsString()
  @IsOptional()
  descripcion?: string;

  @IsString()
  @IsOptional()
  foto_url?: string;

  @IsUUID('4', { message: 'El ID de categoría debe ser un UUID válido' })
  @IsOptional()
  categoria_id?: string;

  @IsBoolean()
  @IsOptional()
  disponible?: boolean;
}
