//! In-process cache + rate limiter for AI-generated hints.
//!
//! Plan 7: cache identical (exercise_id, answer_history) pairs in a HashMap
//! with a per-entry TTL so repeated wrong answers within the cache window get
//! the same hint back without hitting the Anthropic API. A per-exercise
//! counter enforces the "max 3 hints per session" limit.
//!
//! No external dependencies (no Redis). This is in-memory only — fine for a
//! single-instance service. A multi-instance deploy would need to swap this
//! for a shared cache (Redis, Memcached) without changing the public API.

use std::collections::HashMap;
use std::time::{Duration, Instant};

/// Result of an attempt to use the rate limiter.
#[derive(Debug, PartialEq, Eq)]
pub enum RateLimit {
    /// Within budget; remaining counts left in window.
    Allowed { remaining: u32 },
    /// Quota exhausted; caller should refuse the request (e.g. return 429).
    Denied,
}

/// Simple per-key rate limiter with a fixed quota per window.
#[derive(Debug)]
pub struct RateLimiter {
    /// Max requests per window per key.
    quota: u32,
    /// Per-key count + window start.
    counters: HashMap<String, (u32, Instant)>,
}

impl RateLimiter {
    pub fn new(quota: u32) -> Self {
        Self {
            quota,
            counters: HashMap::new(),
        }
    }

    /// Record one request for `key` and return the verdict.
    /// After the window elapses, the counter resets.
    pub fn try_acquire(&mut self, key: &str, window: Duration) -> RateLimit {
        let now = Instant::now();
        let entry = self.counters.entry(key.to_string()).or_insert((0, now));
        if now.duration_since(entry.1) >= window {
            *entry = (1, now);
            return RateLimit::Allowed {
                remaining: self.quota.saturating_sub(1),
            };
        }
        if entry.0 >= self.quota {
            RateLimit::Denied
        } else {
            entry.0 += 1;
            RateLimit::Allowed {
                remaining: self.quota - entry.0,
            }
        }
    }

    /// Reset the counter for a key (e.g. session boundary).
    pub fn reset(&mut self, key: &str) {
        self.counters.remove(key);
    }

    /// How many keys are currently tracked (test helper).
    pub fn tracked_keys(&self) -> usize {
        self.counters.len()
    }
}

/// Cache entry: (hint, inserted_at).
#[derive(Debug, Clone)]
pub struct CachedHint {
    pub text: String,
    pub inserted_at: Instant,
}

/// Bounded LRU-ish in-process cache: stores entries until either TTL expires
/// or the size cap is reached, then evicts the oldest entry.
pub struct HintCache {
    entries: HashMap<String, CachedHint>,
    ttl: Duration,
    max_size: usize,
    /// Monotonic counter to break ties when choosing what to evict.
    insertion_order: u64,
}

impl HintCache {
    pub fn new(ttl: Duration, max_size: usize) -> Self {
        Self {
            entries: HashMap::new(),
            ttl,
            max_size,
            insertion_order: 0,
        }
    }

    pub fn get(&self, key: &str) -> Option<&str> {
        let now = Instant::now();
        self.entries.get(key).and_then(|e| {
            if now.duration_since(e.inserted_at) < self.ttl {
                Some(e.text.as_str())
            } else {
                None
            }
        })
    }

    pub fn insert(&mut self, key: String, text: String) {
        if self.entries.len() >= self.max_size && !self.entries.contains_key(&key) {
            self.evict_one();
        }
        self.insertion_order += 1;
        self.entries.insert(
            key,
            CachedHint {
                text,
                inserted_at: Instant::now(),
            },
        );
    }

    fn evict_one(&mut self) {
        // Find entry with smallest insertion_order; we don't track it
        // per-entry, so fall back to oldest inserted_at.
        if let Some(oldest_key) = self
            .entries
            .iter()
            .min_by_key(|(_, e)| e.inserted_at)
            .map(|(k, _)| k.clone())
        {
            self.entries.remove(&oldest_key);
        }
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Drop all expired entries. Cheap O(n).
    pub fn purge_expired(&mut self) {
        let now = Instant::now();
        self.entries
            .retain(|_, e| now.duration_since(e.inserted_at) < self.ttl);
    }
}

/// Compute a stable cache key from (exercise_id, answer_history).
/// Order matters: `["3","7"]` and `["7","3"]` should map to the same key
/// because the LLM prompt only needs to know the set, not the sequence.
/// We use a sorted, length-prefixed encoding to avoid collisions like
/// `["12","3"]` vs `["1","23"]`.
pub fn cache_key(exercise_id: &str, history: &[String]) -> String {
    let mut sorted: Vec<&str> = history.iter().map(String::as_str).collect();
    sorted.sort();
    let mut key = String::with_capacity(exercise_id.len() + 16);
    key.push_str(exercise_id);
    for h in sorted {
        key.push('|');
        key.push_str(&h.len().to_string());
        key.push(':');
        key.push_str(h);
    }
    key
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rate_limiter_allows_up_to_quota() {
        let mut rl = RateLimiter::new(3);
        let window = Duration::from_secs(60);
        assert_eq!(
            rl.try_acquire("ex1", window),
            RateLimit::Allowed { remaining: 2 }
        );
        assert_eq!(
            rl.try_acquire("ex1", window),
            RateLimit::Allowed { remaining: 1 }
        );
        assert_eq!(
            rl.try_acquire("ex1", window),
            RateLimit::Allowed { remaining: 0 }
        );
    }

    #[test]
    fn rate_limiter_denies_after_quota() {
        let mut rl = RateLimiter::new(2);
        let window = Duration::from_secs(60);
        assert_eq!(
            rl.try_acquire("ex1", window),
            RateLimit::Allowed { remaining: 1 }
        );
        assert_eq!(
            rl.try_acquire("ex1", window),
            RateLimit::Allowed { remaining: 0 }
        );
        assert_eq!(rl.try_acquire("ex1", window), RateLimit::Denied);
        // Quota still denied on subsequent calls.
        assert_eq!(rl.try_acquire("ex1", window), RateLimit::Denied);
    }

    #[test]
    fn rate_limiter_keys_are_independent() {
        let mut rl = RateLimiter::new(1);
        let window = Duration::from_secs(60);
        assert_eq!(
            rl.try_acquire("a", window),
            RateLimit::Allowed { remaining: 0 }
        );
        assert_eq!(
            rl.try_acquire("b", window),
            RateLimit::Allowed { remaining: 0 }
        );
        // 'a' still denied
        assert_eq!(rl.try_acquire("a", window), RateLimit::Denied);
    }

    #[test]
    fn rate_limiter_reset_clears_counter() {
        let mut rl = RateLimiter::new(1);
        let window = Duration::from_secs(60);
        assert_eq!(
            rl.try_acquire("a", window),
            RateLimit::Allowed { remaining: 0 }
        );
        assert_eq!(rl.try_acquire("a", window), RateLimit::Denied);
        rl.reset("a");
        assert_eq!(
            rl.try_acquire("a", window),
            RateLimit::Allowed { remaining: 0 }
        );
    }

    #[test]
    fn rate_limiter_zero_quota_denies_everything() {
        let mut rl = RateLimiter::new(0);
        let window = Duration::from_secs(60);
        assert_eq!(rl.try_acquire("a", window), RateLimit::Denied);
    }

    #[test]
    fn cache_hit_returns_inserted_text() {
        let mut cache = HintCache::new(Duration::from_secs(60), 10);
        cache.insert("k".to_string(), "hint".to_string());
        assert_eq!(cache.get("k"), Some("hint"));
    }

    #[test]
    fn cache_miss_for_unknown_key() {
        let cache = HintCache::new(Duration::from_secs(60), 10);
        assert_eq!(cache.get("nope"), None);
    }

    #[test]
    fn cache_evicts_when_full() {
        let mut cache = HintCache::new(Duration::from_secs(60), 2);
        cache.insert("a".to_string(), "A".to_string());
        cache.insert("b".to_string(), "B".to_string());
        // Full now. Next insert must evict.
        cache.insert("c".to_string(), "C".to_string());
        assert_eq!(cache.len(), 2);
        // 'c' is in; one of {a, b} is gone.
        assert_eq!(cache.get("c"), Some("C"));
    }

    #[test]
    fn cache_overwrite_existing_key_does_not_grow() {
        let mut cache = HintCache::new(Duration::from_secs(60), 3);
        cache.insert("a".to_string(), "v1".to_string());
        cache.insert("a".to_string(), "v2".to_string());
        assert_eq!(cache.len(), 1);
        assert_eq!(cache.get("a"), Some("v2"));
    }

    #[test]
    fn cache_purge_expired_removes_old() {
        let mut cache = HintCache::new(Duration::from_millis(50), 10);
        cache.insert("a".to_string(), "A".to_string());
        std::thread::sleep(Duration::from_millis(80));
        cache.purge_expired();
        assert_eq!(cache.len(), 0);
    }

    #[test]
    fn cache_key_is_stable_for_history_reorder() {
        let a = cache_key("ex1", &["3".into(), "7".into()]);
        let b = cache_key("ex1", &["7".into(), "3".into()]);
        assert_eq!(a, b);
    }

    #[test]
    fn cache_key_differs_per_exercise() {
        let a = cache_key("ex1", &["3".into()]);
        let b = cache_key("ex2", &["3".into()]);
        assert_ne!(a, b);
    }

    #[test]
    fn cache_key_length_prefix_prevents_collision() {
        // Without length prefix: ["12","3"] and ["1","23"] would concat
        // the same way. With length prefix, "12" -> "|2:12" and "1" -> "|1:1".
        let a = cache_key("e", &["12".into(), "3".into()]);
        let b = cache_key("e", &["1".into(), "23".into()]);
        assert_ne!(a, b, "key collision: {a} == {b}");
    }

    #[test]
    fn cache_key_handles_empty_history() {
        let a = cache_key("ex1", &[]);
        assert_eq!(a, "ex1");
    }

    #[test]
    fn cache_key_handles_unicode_answers() {
        let k = cache_key("ex1", &["mười".into(), "bảy".into()]);
        assert!(k.contains("mười") && k.contains("bảy"));
    }
}
