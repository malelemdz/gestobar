import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { BarsModule } from './bars/bars.module';
import { UsersModule } from './users/users.module';
import { RolesModule } from './roles/roles.module';
import { AuthModule } from './auth/auth.module';
import { SeedModule } from './seed/seed.module';
import { CategoriesModule } from './categories/categories.module';
import { ProductsModule } from './products/products.module';
import { CajasModule } from './cajas/cajas.module';
import { VentasModule } from './ventas/ventas.module';
import { MenuModule } from './menu/menu.module';
import { AuditoriaModule } from './auditoria/auditoria.module';
import { EstadisticasModule } from './estadisticas/estadisticas.module';
import { TarifasModule } from './tarifas/tarifas.module';
import { UploadsModule } from './uploads/uploads.module';
import { ClsModule } from 'nestjs-cls';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { AuditInterceptor } from './auditoria/audit.interceptor';
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST'),
        port: configService.get<number>('DB_PORT'),
        username: configService.get<string>('DB_USERNAME'),
        password: configService.get<string>('DB_PASSWORD'),
        database: configService.get<string>('DB_DATABASE'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: true,
      }),
    }),
    ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'),
      serveRoot: '/uploads',
    }),
    ClsModule.forRoot({
      global: true,
      middleware: { mount: true },
    }),
    BarsModule,
    UsersModule,
    RolesModule,
    AuthModule,
    SeedModule,
    CategoriesModule,
    ProductsModule,
    CajasModule,
    VentasModule,
    MenuModule,
    AuditoriaModule,
    EstadisticasModule,
    TarifasModule,
    UploadsModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_INTERCEPTOR,
      useClass: AuditInterceptor,
    },
  ],
})
export class AppModule {}
