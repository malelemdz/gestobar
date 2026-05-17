import { IsUUID, IsInt, Min, IsBoolean, IsOptional } from 'class-validator';

export class CreateVentaItemDto {
  @IsUUID('4', { message: 'El ID de variante debe ser un UUID válido' })
  variante_id: string;

  @IsInt({ message: 'La cantidad debe ser un número entero' })
  @Min(1, { message: 'La cantidad mínima es 1' })
  cantidad: number;

  @IsBoolean()
  @IsOptional()
  es_precio_b?: boolean;

  @IsUUID('4', { message: 'El ID de dama debe ser un UUID válido' })
  @IsOptional()
  dama_id?: string;

  @IsBoolean()
  @IsOptional()
  es_invitacion?: boolean;
}
