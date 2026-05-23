import { IsString, IsNotEmpty, IsArray, ValidateNested, ArrayMinSize, IsOptional, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateVentaItemDto } from './create-venta-item.dto';

export class CreateVentaDto {
  @IsString()
  @IsNotEmpty({ message: 'El método de pago es obligatorio' })
  metodo_pago: string;

  @IsArray()
  @ArrayMinSize(1, { message: 'La venta debe contener al menos un producto' })
  @ValidateNested({ each: true })
  @Type(() => CreateVentaItemDto)
  items: CreateVentaItemDto[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  monto_efectivo?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  monto_tarjeta?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  monto_tr_qr?: number;
}
