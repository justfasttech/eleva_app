var PasskeyAuthenticator = {
  init: function() {},
  register: function() { return Promise.reject("Passkeys not supported"); },
  login: function() { return Promise.reject("Passkeys not supported"); },
  cancelCurrentAuthenticatorOperation: function() {},
  isUserVerifyingPlatformAuthenticatorAvailable: function() { return Promise.resolve(false); },
  isConditionalMediationAvailable: function() { return Promise.resolve(false); },
  hasPasskeySupport: function() { return false; }
};
