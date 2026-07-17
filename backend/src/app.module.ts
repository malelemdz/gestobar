import { Module, OnApplicationBootstrap } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
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
import { SocketModule } from './socket/socket.module';
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const databaseUrl = configService.get<string>('DATABASE_URL');
        // Coolify provee DATABASE_URL cuando lincas un Postgres.
        // Si existe, la usamos directamente. Si no, usamos variables individuales.
        if (databaseUrl) {
          return {
            type: 'postgres',
            url: databaseUrl,
            entities: [__dirname + '/**/*.entity{.ts,.js}'],
            synchronize: true,
          };
        }
        return {
          type: 'postgres',
          host: configService.get<string>('DB_HOST'),
          port: configService.get<number>('DB_PORT'),
          username: configService.get<string>('DB_USERNAME'),
          password: configService.get<string>('DB_PASSWORD'),
          database: configService.get<string>('DB_DATABASE'),
          entities: [__dirname + '/**/*.entity{.ts,.js}'],
          synchronize: true,
        };
      },
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
    SocketModule,
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
export class AppModule implements OnApplicationBootstrap {
  constructor(private readonly dataSource: DataSource) {}

  async onApplicationBootstrap() {
    try {
      console.log('--- RUNNING DB INITIALIZATION QUERY FOR BAR CONFIG TABS ---');
      await this.dataSource.query(`
        UPDATE bares 
        SET configuracion_tabs_permitidas = '{"identidad": true, "redes": true, "operaciones": true, "horario": true, "compania": true, "tarifas": true}'
        WHERE configuracion_tabs_permitidas IS NULL;
      `);
      console.log('--- DB INITIALIZATION QUERY EXECUTED SUCCESSFULLY ---');
    } catch (error) {
      console.error('Error running DB initialization query:', error);
    }
  }
}
