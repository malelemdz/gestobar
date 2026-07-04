import { Controller, Post, Headers, ForbiddenException } from '@nestjs/common';
import { SeedService } from './seed.service';

@Controller('seed')
export class SeedController {
  constructor(private readonly seedService: SeedService) {}

  @Post()
  executeSeed(@Headers('x-seed-key') seedKey: string) {
    const validKey = process.env.SEED_SECRET_KEY;

    // Si no hay clave configurada en el entorno, el endpoint está deshabilitado
    if (!validKey) {
      throw new ForbiddenException('Seed endpoint is disabled: SEED_SECRET_KEY is not configured.');
    }

    // Verificar que la clave del header coincide con la del entorno
    if (seedKey !== validKey) {
      throw new ForbiddenException('Invalid seed key.');
    }

    return this.seedService.runSeed();
  }
}
