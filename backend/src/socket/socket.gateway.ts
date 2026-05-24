import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class SocketGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket) {
    console.log(`Cliente conectado a WebSockets (Global): ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Cliente desconectado de WebSockets (Global): ${client.id}`);
  }

  @SubscribeMessage('suscribir_dama')
  handleSubscribeDama(client: Socket, payload: { damaId: string }) {
    if (payload && payload.damaId) {
      // Unirse a una sala única con el ID de la dama para recibir notificaciones privadas
      client.join(payload.damaId);
      client.emit('suscrito', { mensaje: `Suscrito con éxito a notificaciones de Dama ${payload.damaId}` });
      console.log(`Dama ${payload.damaId} suscrita a su canal privado: Socket ${client.id}`);
    }
  }

  notificarComision(damaId: string, data: any) {
    // Enviar evento de comisión en tiempo real únicamente a la Dama correspondiente
    this.server.to(damaId).emit('nueva_comision', data);
  }

  emitirEventoBar(barId: string, eventName: string, data: any) {
    // Emite un evento filtrado por el ID del Bar para mantener el aislamiento
    this.server.emit(`${eventName}_bar_${barId}`, data);
  }
}
