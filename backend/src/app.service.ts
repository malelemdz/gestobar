import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth(): object {
    return {
      app: 'GestoBar API',
      status: 'ok',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    };
  }
}
