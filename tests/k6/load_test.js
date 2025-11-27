// tests/k6/load_test.js

import http from 'k6/http';
import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { scenario } from 'k6/execution';
import { config, getDurationMs } from './config.js';
import {
  connectFrame,
  subscribeFrame,
  sendFrame,
  parseFrame,
  generateUniqueUserCredentials,
  generateRoomParticipantLists,
} from './utils.js';
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

export const options = {
  scenarios: {
    phase1: {
      executor: 'constant-vus',
      vus: config.phases.phase1.users,
      duration: config.phases.phase1.duration,
      startTime: config.phases.phase1.startTime,
      env: { PHASE: 'phase1' },
    },
    phase2: {
      executor: 'constant-vus',
      vus: config.phases.phase2.users,
      duration: config.phases.phase2.duration,
      startTime: config.phases.phase2.startTime,
      env: { PHASE: 'phase2' },
    },
    phase3: {
      executor: 'constant-vus',
      vus: config.phases.phase3.users,
      duration: config.phases.phase3.duration,
      startTime: config.phases.phase3.startTime,
      env: { PHASE: 'phase3' },
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    ws_connecting: ['p(95)<1000'],
  },
};

// Setup: Create users and rooms, return all data
export function setup() {
  const runTimestamp = Date.now().toString();

  // Create users for the maximum VU count across all phases
  const maxUsers = Math.max(
    config.phases.phase1.users,
    config.phases.phase2.users,
    config.phases.phase3.users
  );

  console.log(`=== SETUP: Creating ${maxUsers} users ===`);

  const users = [];
  const userDataForCSV = [];

  // Create users
  for (let i = 1; i <= maxUsers; i++) {
    const creds = generateUniqueUserCredentials(i, runTimestamp);

    // Register
    const regPayload = JSON.stringify({
      email: creds.email,
      password: creds.password,
      firstName: creds.firstName,
      lastName: creds.lastName,
    });

    const regRes = http.post(
      `${config.baseUrl}/api/auth/signup`,
      regPayload,
      { headers: { 'Content-Type': 'application/json' } }
    );

    if (regRes.status !== 200 && regRes.status !== 400) {
      console.error(`Failed to register user ${i}: ${regRes.status} - ${regRes.body}`);
      continue;
    }

    // Login
    const loginPayload = JSON.stringify({
      email: creds.email,
      password: creds.password,
    });

    const loginRes = http.post(
      `${config.baseUrl}/api/auth/login`,
      loginPayload,
      { headers: { 'Content-Type': 'application/json' } }
    );

    if (loginRes.status !== 200) {
      console.error(`Failed to login user ${i}: ${loginRes.status} - ${loginRes.body}`);
      continue;
    }

    const userData = {
      userId: loginRes.json('data.user.id'),
      token: loginRes.json('data.token'),
      email: creds.email,
      password: creds.password, // Store password
    };

    users.push(userData);
    userDataForCSV.push(`${userData.email},${userData.password}`);
  }

  console.log(`Successfully created ${users.length} users`);

  // Create rooms for CURRENT phase
  const phaseName = __ENV.PHASE || 'phase1';
  const phaseConfig = config.phases[phaseName];

  // Generate room participant lists
  const roomParticipantLists = generateRoomParticipantLists(
    users,
    phaseConfig.totalRooms,
    Math.min(config.maxParticipantsPerRoom, users.length)
  );

  // Create rooms and track user-room mappings
  const userRoomsMap = {};
  users.forEach(user => {
    userRoomsMap[user.userId] = [];
  });

  // Create rooms
  roomParticipantLists.forEach((participants, roomIndex) => {
    if (participants.length === 0) return;

    const creator = participants[0];
    const participantEmails = participants.slice(1).map(p => p.email);

    const roomName = `${config.roomNamePrefix}_${roomIndex}_${creator.userId}`;

    const payload = JSON.stringify({
      name: roomName,
      description: config.roomDescription,
      participantEmails: participantEmails,
    });

    const res = http.post(
      `${config.baseUrl}/api/rooms`,
      payload,
      {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${creator.token}`,
        },
      }
    );

    if (res.status === 200 || res.status === 201) {
      const roomId = res.json('data.id') || res.json('id');
      const roomData = {
        id: roomId,
        name: roomName,
        destination: `/topic/room.${roomId}`,
        isCreator: false,
        participants: participantEmails,
      };

      // Add to all participants' room lists
      participants.forEach(participant => {
        const isCreator = participant.userId === creator.userId;
        userRoomsMap[participant.userId].push({
          ...roomData,
          isCreator: isCreator,
        });
      });
    } else {
      console.error(`Failed to create room ${roomIndex}: ${res.status} - ${res.body}`);
    }
  });

  console.log(`Setup complete: ${users.length} users, ${roomParticipantLists.length} rooms created`);

  return {
    users,
    userRoomsMap,
    phaseConfig,
    runTimestamp,
    userDataForCSV: userDataForCSV.join('\n'), // Pass user data to handleSummary
  };
}

// VU Code: User Journey with reactive fetching
export default function(data) {
  // ✅ FIX: Safe user mapping with modulo
  const userIndex = (__VU - 1) % data.users.length;
  const user = data.users[userIndex];

  if (!user) {
    console.error(`VU ${__VU}: No user at index ${userIndex}`);
    return;
  }

  const userRooms = data.userRoomsMap[user.userId] || [];

  if (!userRooms.length) {
    console.warn(`VU ${__VU} (User ${user.userId}): No rooms assigned`);
    return;
  }

  console.log(`VU ${__VU}: User ${user.userId} (${user.email}) has ${userRooms.length} rooms`);

  let roomsData = [];
  let messagesMap = {};

  // Calculate phase duration in milliseconds
  const phaseDurationMs = getDurationMs(data.phaseConfig.duration);
  console.log(`VU ${__VU}: Phase duration = ${phaseDurationMs}ms`);

  // 1. Connect WebSocket
  const wsUrl = config.wsUrl;

  const wsResponse = ws.connect(wsUrl, { tags: { phase: __ENV.PHASE, user_id: user.userId } }, function(socket) {
    let stompConnected = false;
    let messageCount = 0;

    socket.on('open', function() {
      console.log(`VU ${__VU}: WebSocket opened, sending CONNECT frame`);
      socket.send(connectFrame(user.token));
    });

    socket.on('message', function(message) {
      console.log(`VU ${__VU}: Received STOMP frame: ${message.substring(0, 100)}...`);
      const frame = parseFrame(message);
      if (!frame || !frame.command) {
        console.error(`VU ${__VU}: Failed to parse frame`);
        return;
      }

      if (frame.command === 'CONNECTED') {
        console.log(`VU ${__VU}: STOMP CONNECTED successfully`);
        stompConnected = true;

        // 2. Subscribe to room updates
        socket.send(subscribeFrame(`room-updates-${user.userId}`, `/user/queue/roomUpdates`));
        console.log(`VU ${__VU}: Subscribed to room updates`);

        // 3. Fetch rooms
        const roomsRes = http.get(
          `${config.baseUrl}/api/rooms`,
          { headers: { Authorization: `Bearer ${user.token}` } }
        );

        if (check(roomsRes, { 'get rooms status 200': (r) => r.status === 200 })) {
          roomsData = roomsRes.json('data') || [];
          console.log(`VU ${__VU}: Fetched ${roomsData.length} rooms`);
        }

        // 4. Process each room
        roomsData.forEach(roomDto => {
          const roomId = roomDto.id;

          // Subscribe to room
          socket.send(subscribeFrame(`room-${roomId}`, `/topic/room.${roomId}`));
          console.log(`VU ${__VU}: Subscribed to room ${roomId}`);

          // Fetch initial messages
          const messagesRes = http.get(
            `${config.baseUrl}/api/rooms/${roomId}/messages?page=0&size=20`,
            { headers: { Authorization: `Bearer ${user.token}` } }
          );

          if (check(messagesRes, { 'get messages status 200': (r) => r.status === 200 })) {
            messagesMap[roomId] = messagesRes.json('data.content') || [];
            console.log(`VU ${__VU}: Fetched ${messagesMap[roomId].length} messages for room ${roomId}`);
          }

          // Start sending messages
          const intervalMs = 1000 / data.phaseConfig.msgRate;
          console.log(`VU ${__VU}: Starting message loop for room ${roomId} at ${intervalMs}ms interval`);

          socket.setInterval(() => {
            if (!stompConnected) {
              console.warn(`VU ${__VU}: STOMP not connected, skipping message`);
              return;
            }

            const msg = {
              roomId: roomId,
              content: config.messageTemplate
                .replace('USER_ID', user.userId)
                .replace('ROOM_ID', roomId),
              messageType: 'TEXT',
            };

            socket.send(sendFrame('/app/chat.sendMessage', msg));
            messageCount++;

            if (messageCount % 50 === 0) {
              console.log(`VU ${__VU}: Sent ${messageCount} messages so far`);
            }
          }, intervalMs);
        });
      } else if (frame.command === 'MESSAGE') {
        console.log(`VU ${__VU}: Received MESSAGE on ${frame.headers.destination}`);

        // On room update: refetch rooms
        if (frame.headers.destination === `/user/queue/roomUpdates`) {
          console.log(`VU ${__VU}: Room update received, refetching rooms`);
          const roomsRes = http.get(
            `${config.baseUrl}/api/rooms`,
            { headers: { Authorization: `Bearer ${user.token}` } }
          );

          if (check(roomsRes, { 're-fetch rooms status 200': (r) => r.status === 200 })) {
            roomsData = roomsRes.json('data') || [];
          }
        }

        // On room message: refetch messages
        if (frame.headers.destination.startsWith('/topic/room.')) {
          const roomId = frame.headers.destination.replace('/topic/room.', '');
          console.log(`VU ${__VU}: Message in room ${roomId}, refetching messages`);
          const messagesRes = http.get(
            `${config.baseUrl}/api/rooms/${roomId}/messages?page=0&size=20`,
            { headers: { Authorization: `Bearer ${user.token}` } }
          );

          if (check(messagesRes, { 're-fetch messages status 200': (r) => r.status === 200 })) {
            messagesMap[roomId] = messagesRes.json('data.content') || [];
          }
        }
      } else if (frame.command === 'ERROR') {
        console.error(`VU ${__VU}: STOMP ERROR: ${frame.body}`);
      }
    });

    socket.on('error', function(e) {
      console.error(`VU ${__VU}: WebSocket error:`, e);
      stompConnected = false;
    });

    socket.on('close', function() {
      console.log(`VU ${__VU}: WebSocket closed`);
      stompConnected = false;
    });

    // Keep connection alive
    console.log(`VU ${__VU}: Setting socket timeout to ${phaseDurationMs}ms`);
    socket.setTimeout(() => {
      console.log(`VU ${__VU}: Timeout reached, closing socket`);
      socket.close();
    }, phaseDurationMs);
  });

  // Check WebSocket connection
  const wsSuccess = check(wsResponse, {
    'ws status is 101': (r) => {
      if (!r) {
        console.error(`VU ${__VU}: WebSocket response is null/undefined`);
        return false;
      }
      if (r.status !== 101) {
        console.error(`VU ${__VU}: WebSocket status is ${r.status}, expected 101`);
      }
      return r.status === 101;
    }
  });

  if (!wsSuccess) {
    console.error(`VU ${__VU}: WebSocket connection failed`);
  }

  // Keep VU alive
  console.log(`VU ${__VU}: Sleeping for ${phaseDurationMs}ms`);
  sleep(phaseDurationMs / 1000); // sleep takes seconds
}

// Summary with actual user data
export function handleSummary(data) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

  // Extract user data from setup return value
  const userCSV = data.userDataForCSV || 'No users created';

  // Create console log dump
  const consoleOutput = `=== CONSOLE LOG DUMP ===\n${new Date().toISOString()}\n\nUser data:\n${userCSV}\n\nTest data:\n${JSON.stringify(data, null, 2)}\n\n=== END LOG DUMP ===`;

  return {
    [`summary_${timestamp}.html`]: htmlReport(data),
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    [`users_${timestamp}.csv`]: `email,password\n${userCSV}`,
    [`console_${timestamp}.log`]: consoleOutput,
  };
}
