module.exports = {
  testEnvironment: 'jsdom',
  roots: ['spec/javascript'],
  moduleDirectories: ['node_modules', 'app/javascript'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/app/javascript/$1'
  },
  transform: {
    '^.+\\.jsx?$': 'babel-jest'
  },
  setupFilesAfterEnv: ['<rootDir>/spec/javascript/setup.js']
};
