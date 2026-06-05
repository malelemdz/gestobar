import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { types } from 'pg';

// Configurar pg para interpretar columnas timestamp (sin huso horario) como UTC
types.setTypeParser(1114, (stringValue: string) => {
  return new Date(stringValue + 'Z');
});


async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
