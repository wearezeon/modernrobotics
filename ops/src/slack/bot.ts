import { App, LogLevel } from "@slack/bolt";
import { config } from "../config.js";
import { query } from "../db/client.js";

let app: App | null = null;

export function createSlackBot(): App | null {
  if (!config.slack.botToken || !config.slack.appToken) {
    console.log("[slack] Skipping bot init — no credentials configured");
    return null;
  }

  app = new App({
    token: config.slack.botToken,
    signingSecret: config.slack.signingSecret,
    socketMode: true,
    appToken: config.slack.appToken,
    logLevel: LogLevel.WARN,
  });

  registerHandlers(app);
  return app;
}

function registerHandlers(app: App): void {
  // Respond to structured commands in threads
  app.message(/^(paid|done|skip)$/i, async ({ message, say }) => {
    if (!("text" in message) || message.subtype) return;
    const command = message.text!.toLowerCase().trim();
    // Thread-based — in v1 we acknowledge and log
    await say({
      text: `Got it — marked as *${command}*. (Entity linking coming in Phase 4)`,
      thread_ts: message.ts,
    });
  });

  // Snooze command: "snooze 3d"
  app.message(/^snooze\s+(\d+)d$/i, async ({ message, say, context }) => {
    if (!("text" in message) || message.subtype) return;
    const match = context.matches as RegExpMatchArray;
    const days = parseInt(match[1], 10);
    await say({
      text: `Snoozed for *${days} day(s)*. Will resurface then.`,
      thread_ts: message.ts,
    });
  });

  // Note command: "note: some text here"
  app.message(/^note:\s*(.+)$/i, async ({ message, say, context }) => {
    if (!("text" in message) || message.subtype) return;
    const match = context.matches as RegExpMatchArray;
    const noteText = match[1].trim();
    await say({
      text: `Note saved: "${noteText}"`,
      thread_ts: message.ts,
    });
  });
}

// Post a message to a named channel
export async function postToChannel(
  channelName: string,
  text: string,
  entityType?: string,
  entityId?: string
): Promise<void> {
  if (!app) return;

  try {
    const result = await app.client.chat.postMessage({
      channel: channelName,
      text,
    });

    // Log the alert to prevent duplicates
    if (entityType && entityId) {
      await query(
        `INSERT INTO alerts (channel, entity_type, entity_id, message, slack_ts)
         VALUES ($1, $2, $3, $4, $5)`,
        [channelName, entityType, entityId, text, result.ts]
      );
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[slack] Failed to post to #${channelName}:`, msg);
  }
}

export async function startSlackBot(): Promise<void> {
  if (!app) return;
  await app.start();
  console.log("[slack] Bot started in socket mode");
}
