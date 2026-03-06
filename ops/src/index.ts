import cron from "node-cron";
import { config } from "./config.js";
import { shutdown as shutdownDb } from "./db/client.js";
import { pollInbox } from "./mail/imap.js";
import { createSlackBot, startSlackBot } from "./slack/bot.js";

async function main() {
  console.log("[ops] Beverly Hills Cop — starting up");
  console.log(`[ops] Timezone: ${config.tz}`);

  // Initialize Slack bot (skips if no credentials)
  createSlackBot();
  await startSlackBot();

  // Schedule IMAP polling
  const interval = config.imap.pollIntervalMinutes;
  cron.schedule(`*/${interval} * * * *`, async () => {
    console.log("[ops] Running scheduled IMAP poll...");
    await pollInbox();
  });
  console.log(`[ops] IMAP poll scheduled every ${interval} min`);

  // Initial poll on startup
  await pollInbox();

  console.log("[ops] System ready. Waiting for signals.");
}

// Graceful shutdown
function onShutdown(signal: string) {
  console.log(`[ops] Received ${signal}, shutting down...`);
  shutdownDb().then(() => process.exit(0));
}
process.on("SIGINT", () => onShutdown("SIGINT"));
process.on("SIGTERM", () => onShutdown("SIGTERM"));

main().catch((err) => {
  console.error("[ops] Fatal:", err);
  process.exit(1);
});
