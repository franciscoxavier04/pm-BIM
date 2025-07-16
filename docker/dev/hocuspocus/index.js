import { Server } from "@hocuspocus/server";
import { createVerifier } from 'fast-jwt'

const secret = "secret12345"
const verifyToken = createVerifier({
  key: async () => secret,
  algorithms: ['HS256'],
})
const server = new Server({
  port: 1234,
  quite: false,
  onConnect(data) {
    console.log('Client connected:', data);
  },
  async onAuthenticate(data) {
    const { token, documentName } = data;
    if (!token) {
      throw new Error('Unauthorized: Token missing.')
    }
    let tokenPayload;
    try {
      tokenPayload = await verifyToken(token)
    } catch (err) {
      throw new Error('Unauthorized: Invalid token.')
    }
    console.log('Token payload:', tokenPayload);
    if(documentName != tokenPayload.document_id) {
      throw new Error('Unauthorized: Invalid token. This document cannot be accessed with this token.')
    }
  },
});

server.listen();
