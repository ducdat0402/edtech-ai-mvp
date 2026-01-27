import type { IncomingMessage, ServerResponse } from 'http';
import { createApp } from '../src/main';

let cachedHandler: ((req: IncomingMessage, res: ServerResponse) => void) | null =
  null;

async function getRequestHandler() {
  if (!cachedHandler) {
    const app = await createApp();
    const expressApp = app.getHttpAdapter().getInstance();
    cachedHandler = (req: IncomingMessage, res: ServerResponse) =>
      expressApp(req, res);
  }

  return cachedHandler;
}

export default async function handler(
  req: IncomingMessage,
  res: ServerResponse,
) {
  const requestHandler = await getRequestHandler();
  return requestHandler(req, res);
}

