import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { DmService } from './dm.service';

@WebSocketGateway({
  namespace: 'dm',
  cors: { origin: true },
})
export class DmGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private dmService: DmService,
  ) {}

  async handleConnection(client: any) {
    const token =
      client.handshake?.auth?.token ||
      client.handshake?.query?.token ||
      (client.handshake?.headers?.authorization as string)?.replace('Bearer ', '');
    if (!token) {
      client.disconnect();
      return;
    }
    try {
      const secret = this.configService.get<string>('JWT_SECRET');
      const payload = this.jwtService.verify(token, { secret });
      const userId = payload.sub;
      if (!userId) {
        client.disconnect();
        return;
      }
      client.join(`user:${userId}`);
      client.data.userId = userId;
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(_client: any) {}

  @SubscribeMessage('send_message')
  async handleSendMessage(
    client: any,
    payload: { peerId: string; content: string; replyToId?: string },
  ): Promise<void> {
    const userId = client.data?.userId;
    if (!userId || !payload?.peerId || typeof payload.content !== 'string') return;
    try {
      const msg = await this.dmService.sendMessage(
        userId,
        payload.peerId,
        payload.content,
        payload.replyToId,
      );
      const out: Record<string, any> = {
        id: msg.id,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        content: msg.content,
        createdAt: msg.createdAt,
      };
      if (msg.replyToId) out.replyToId = msg.replyToId;
      if (msg.replyTo) {
        out.replyTo = {
          id: msg.replyTo.id,
          content: msg.replyTo.content,
          senderId: msg.replyTo.senderId,
        };
      }
      this.server.to(`user:${payload.peerId}`).emit('new_message', out);
      client.emit('new_message', out);
    } catch (_) {
      client.emit('dm_error', { event: 'send_message', message: 'Gửi tin nhắn thất bại' });
    }
  }

  emitMessageDeleted(messageId: string, senderId: string, receiverId: string): void {
    const payload = { messageId };
    this.server.to(`user:${senderId}`).emit('message_deleted', payload);
    this.server.to(`user:${receiverId}`).emit('message_deleted', payload);
  }

  @SubscribeMessage('typing')
  handleTyping(client: any, payload: { peerId: string }): void {
    const userId = client.data?.userId;
    if (!userId || !payload?.peerId) return;
    this.server.to(`user:${payload.peerId}`).emit('typing', { userId });
  }
}
