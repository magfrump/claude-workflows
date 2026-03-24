// Test fixture for TC-C1.5: Configuration claim
// Comment says 5 minutes, config says 300 seconds — these match

const config = {
  cache: {
    // cache TTL is 5 minutes
    ttl: 300, // seconds
  },
  retry: {
    maxAttempts: 3,
    backoffMs: 1000,
  },
};

function getCacheTTL() {
  return config.cache.ttl;
}

module.exports = { config, getCacheTTL };
