// tests/k6/utils.js

import crypto from 'k6/crypto';
import { config } from './config.js';

export function connectFrame(token) {
  return `CONNECT\naccept-version:1.2,1.1,1.0\nheart-beat:10000,10000\nAuthorization:Bearer ${token}\n\n\0`;
}

export function subscribeFrame(subId, destination) {
  return `SUBSCRIBE\nid:${subId}\ndestination:${destination}\n\n\0`;
}

export function sendFrame(destination, body) {
  // Ensure body is properly formatted JSON
  const payload = typeof body === 'string' ? body : JSON.stringify(body);
  return `SEND\ndestination:${destination}\ncontent-type:application/json\n\n${payload}\0`;
}

export function parseFrame(message) {
  if (!message) {
    console.log('parseFrame: received null message');
    return null;
  }

  try {
    // Remove null terminators
    const cleanMessage = message.replace(/\0/g, '');
    const parts = cleanMessage.split('\n\n');

    if (parts.length < 2) {
      return { command: parts[0] || '', headers: {}, body: '' };
    }

    const headerPart = parts[0];
    const body = parts.slice(1).join('\n\n');

    const headerLines = headerPart.split('\n');
    const command = headerLines[0] || '';
  const headers = {};

    for (let i = 1; i < headerLines.length; i++) {
      const line = headerLines[i];
      const [key, value] = line.split(':');
      if (key && value !== undefined) {
        headers[key] = value;
      }
  }

    return { command, headers, body };
  } catch (e) {
    console.error('parseFrame error:', e, 'message:', message);
    return null;
  }
}

// User generation
export function generateUniqueUserCredentials(userIndex, runTimestamp) {
  return {
    email: `loadtest_${runTimestamp}_user${userIndex}@example.com`,
    password: config.userPassword,
    firstName: `LoadUser${userIndex}${runTimestamp}`,
    lastName: 'Test',
  };
}

// Generate random room participant lists
export function generateRoomParticipantLists(allUsers, totalRooms, maxParticipants) {
  const roomLists = [];
  const availableUsers = [...allUsers];

  for (let i = 0; i < totalRooms; i++) {
    // Random participant count (1 to maxParticipants)
    const participantCount = Math.floor(Math.random() * maxParticipants) + 1;

    // Select unique participants for this room
    const roomParticipants = [];
    const usedIndices = new Set();

    for (let j = 0; j < participantCount && j < availableUsers.length; j++) {
      let idx;
      do {
        idx = Math.floor(Math.random() * availableUsers.length);
      } while (usedIndices.has(idx) && usedIndices.size < availableUsers.length);

      usedIndices.add(idx);
      roomParticipants.push(availableUsers[idx]);
    }

    roomLists.push(roomParticipants);
  }

  return roomLists;
}
