import { loadConfig } from "./config.js";
import { buildServer } from "./server.js";

const config = loadConfig();
const server = await buildServer(config);

try {
  await server.listen({ host: config.host, port: config.port });
} catch (error) {
  server.log.error(error, "Failed to start Carlitos AI decision service.");
  process.exit(1);
}
