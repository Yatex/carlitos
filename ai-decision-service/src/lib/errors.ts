export class ConfigurationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ConfigurationError";
  }
}

export class ProviderExecutionError extends Error {
  constructor(message: string, readonly code: "provider_timeout" | "provider_error", options?: ErrorOptions) {
    super(message, options);
    this.name = "ProviderExecutionError";
  }
}
