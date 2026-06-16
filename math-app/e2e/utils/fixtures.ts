/**
 * Pre-mint JWTs for tests. Real tokens are signed by the auth-service;
 * for mocked backends, any well-formed JWT works.
 */
import type { Page } from '@playwright/test';

export interface MockUser {
  id: string;
  email: string;
  name: string;
  picture: string;
  given_name: string;
  tier: 'free' | 'premium';
  grade: 1 | 2 | 3;
  persona?: 'achiever' | 'gamer' | 'struggler' | 'silent';
  streakDays?: number;
  gems?: number;
}

export const FREE_USER: MockUser = {
  id: 'user-free-1',
  email: 'guest_free@test.local',
  name: 'Bé Test',
  picture: '',
  given_name: 'Bé',
  tier: 'free',
  grade: 1,
  persona: 'achiever',
  streakDays: 3,
  gems: 15,
};

export const PREMIUM_USER: MockUser = {
  ...FREE_USER,
  id: 'user-premium-1',
  email: 'guest_premium@test.local',
  name: 'Bé Premium',
  tier: 'premium',
  grade: 2,
  gems: 999,
};

/** Pre-minted guest access token (used in mocked /api/auth/guest). */
export const FAKE_GUEST_TOKEN = 'fake.jwt.guest-token-test';

/** A pre-minted premium token with `tier=premium` in the payload. */
export const FAKE_PREMIUM_TOKEN = 'fake.jwt.premium-token-test';

export const FACEBOOK_FANPAGE_URL =
  'https://web.facebook.com/profile.php?id=100064784463812';
