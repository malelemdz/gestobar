import { IsString, IsNotEmpty, IsOptional, IsBoolean, IsUrl, IsUUID, IsNumber, Min, Max } from 'class-validator';

export class CreateBarDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsOptional()
  ciudad?: string;

  @IsString()
  @IsOptional()
  direccion?: string;

  @IsString()
  @IsOptional()
  timezone?: string;

  @IsString()
  @IsOptional()
  moneda_simbolo?: string;

  @IsString()
  @IsOptional()
  moneda_iso?: string;

  @IsString()
  @IsOptional()
  logo_url?: string;

  @IsString()
  @IsOptional()
  whatsapp?: string;

  @IsString()
  @IsOptional()
  link_ubicacion?: string;

  @IsString()
  @IsOptional()
  facebook?: string;

  @IsString()
  @IsOptional()
  instagram?: string;

  @IsString()
  @IsOptional()
  tiktok?: string;

  @IsString()
  @IsNotEmpty()
  slug: string;

  @IsUUID()
  @IsNotEmpty()
  owner_id: string;

  @IsBoolean()
  @IsOptional()
  estado?: boolean;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  comision_porcentaje?: number;
}
