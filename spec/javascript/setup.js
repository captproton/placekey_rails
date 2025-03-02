// This file contains setup code for Jest tests

// Mock the fetch API
global.fetch = jest.fn(() => 
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve({})
  })
);

// Mock secure random for IDs
global.crypto = {
  getRandomValues: () => new Uint32Array(10).fill(1)
};

// Add any other global mocks or setup code needed for tests
