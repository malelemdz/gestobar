import { IsString, IsNotEmpty, IsOptional, IsInt, Min } from 'class-validator';

export class CreateCategoryDto {
  @IsString()
  @IsNotEmpty({ message: 'El nombre de la categoría es obligatorio' })
  nombre: string;

  @IsInt()
  @Min(0)
  @IsOptional()
  orden?: number;
}
