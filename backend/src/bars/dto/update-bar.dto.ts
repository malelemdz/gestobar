import { PartialType } from '@nestjs/mapped-types';
import { CreateBarDto } from './create-bar.dto';

import { IsNumber, IsOptional } from 'class-validator';

export class UpdateBarDto extends PartialType(CreateBarDto) {
  @IsNumber()
  @IsOptional()
  tasa_conversion?: number;

  @IsOptional()
  configuracion_tabs_permitidas?: any;
}
