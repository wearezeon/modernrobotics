import "dotenv/config";

function required(key: string): string {
  const val = process.env[key];
  if (!val) throw new Error(`Missing required env var: ${key}`);
  return val;
}

function optional(key: string, fallback: string): string {
  return process.env[key] || fallback;
}

export const config = {
  db: {
    url: required("DATABASE_URL"),
  },
  imap: {
    host: optional("IMAP_HOST", "mail.privateemail.com"),
    port: parseInt(optional("IMAP_PORT", "993"), 10),
    user: process.env.IMAP_USER || "",
    pass: process.env.IMAP_PASS || "",
    pollIntervalMinutes: parseInt(optional("IMAP_POLL_INTERVAL_MINUTES", "15"), 10),
  },
  slack: {
    botToken: process.env.SLACK_BOT_TOKEN || "",
    signingSecret: process.env.SLACK_SIGNING_SECRET || "",
    appToken: process.env.SLACK_APP_TOKEN || "",
    channels: {
      opsDaily: optional("SLACK_CHANNEL_OPS_DAILY", "ops-daily"),
      payments: optional("SLACK_CHANNEL_PAYMENTS", "payments"),
      projects: optional("SLACK_CHANNEL_PROJECTS", "projects"),
      inbox: optional("SLACK_CHANNEL_INBOX", "inbox"),
    },
  },
  tz: optional("TZ", "Europe/Berlin"),
} as const;
