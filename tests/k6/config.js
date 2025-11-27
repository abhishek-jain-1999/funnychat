// tests/k6/config.js

export const config = {
  baseUrl: __ENV.BASE_URL || 'http://chat.abhishek.com/backend',
  wsUrl: __ENV.WS_URL || 'ws://chat.abhishek.com/backend/ws/chat/websocket',

  phases: {
    phase1: { users: 10, totalRooms: 200, msgRate: 1, duration: '1m', startTime: '0s' },
    phase2: { users: 50, totalRooms: 1000, msgRate: 1, duration: '1m', startTime: '1m10s' },
    phase3: { users: 100, totalRooms: 2000, msgRate: 1, duration: '1m', startTime: '2m20s' },
  },

  userPassword: 'password123',
  roomNamePrefix: 'LoadTestRoom',
  roomDescription: 'Load Test Room',
  messageTemplate: 'MSG from USER_ID in ROOM_ID',
  maxParticipantsPerRoom: 20,
};

// Calculate duration in milliseconds for setTimeout
export function getDurationMs(durationStr) {
  const match = durationStr.match(/^(\d+)([smh])$/);
  if (!match) return 60000; // default 1 minute

  const value = parseInt(match[1]);
  const unit = match[2];

  switch (unit) {
    case 's': return value * 1000;
    case 'm': return value * 60 * 1000;
    case 'h': return value * 60 * 60 * 1000;
    default: return 60000;
  }
}
