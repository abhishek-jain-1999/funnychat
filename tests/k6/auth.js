import http from 'k6/http';
import { check } from 'k6';
import { config } from './config.js';

export function registerUser(userIndex) {
    const email = `loadtest_user_${userIndex}@example.com`;
    const password = 'password123';
    const name = `LoadUser${userIndex}`;

    const payload = JSON.stringify({
        email: email,
        password: password,
        firstName: `LoadUser${userIndex}`,
        lastName: 'Test',
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };

    const res = http.post(`${config.baseUrl}/api/auth/signup`, payload, params);

    // 200 OK or 400 (if already exists, which is fine for repeated runs)
    check(res, {
        'register status is 200 or 400': (r) => {
            const ok = r.status === 200 || r.status === 400;
            if (!ok) {
                console.log(`Register failed for ${email}. Status: ${r.status}, Body: ${r.body}`);
            } else {
                console.log(`Register success for ${email}. Status: ${r.status}`);
            }
            return ok;
        },
    });

    return { email, password };
}

export function loginUser(email, password) {
    const payload = JSON.stringify({
        email: email,
        password: password,
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };

    const res = http.post(`${config.baseUrl}/api/auth/login`, payload, params);

    const success = check(res, {
        'login status is 200': (r) => {
            if (r.status !== 200) {
                console.log(`Login status failed for ${email}. Status: ${r.status}, Body: ${r.body}`);
            }
            return r.status === 200;
        },
        'has token': (r) => {
            const hasToken = r.json('data.token') !== undefined;
            if (!hasToken) {
                console.log(`Login token missing for ${email}. Body: ${r.body}`);
            }
            return hasToken;
        },
    });

    if (success) {
        console.log(`Login success for ${email}`);
        return {
            token: res.json('data.token'),
            userId: res.json('data.user.id'), // Adjust based on actual API response
        };
    }
    return null;
}
