import { ImapFlow } from "imapflow";
import { config } from "../config.js";
import { query } from "../db/client.js";

interface ParsedMail {
  messageId: string;
  sender: string;
  subject: string;
  bodySummary: string;
  receivedAt: Date;
}

function createClient(): ImapFlow {
  return new ImapFlow({
    host: config.imap.host,
    port: config.imap.port,
    secure: true,
    auth: {
      user: config.imap.user,
      pass: config.imap.pass,
    },
    logger: false,
  });
}

async function storeMail(mail: ParsedMail): Promise<void> {
  await query(
    `INSERT INTO mail_items (message_id, account, sender, subject, body_summary, received_at)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (message_id) DO NOTHING`,
    [
      mail.messageId,
      "namecheap",
      mail.sender,
      mail.subject,
      mail.bodySummary,
      mail.receivedAt,
    ]
  );
}

export async function pollInbox(): Promise<number> {
  if (!config.imap.user || !config.imap.pass) {
    console.log("[imap] Skipping poll — no credentials configured");
    return 0;
  }

  const client = createClient();
  let count = 0;

  try {
    await client.connect();
    const lock = await client.getMailboxLock("INBOX");

    try {
      // Fetch messages from the last 24 hours
      const since = new Date();
      since.setHours(since.getHours() - 24);

      for await (const message of client.fetch(
        { since },
        { envelope: true, bodyStructure: true }
      )) {
        const envelope = message.envelope;
        if (!envelope?.messageId) continue;

        const parsed: ParsedMail = {
          messageId: envelope.messageId,
          sender: envelope.from?.[0]?.address || "unknown",
          subject: envelope.subject || "(no subject)",
          bodySummary: "",
          receivedAt: envelope.date || new Date(),
        };

        await storeMail(parsed);
        count++;
      }
    } finally {
      lock.release();
    }

    await client.logout();
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[imap] Poll failed:", msg);
  }

  console.log(`[imap] Polled ${count} message(s)`);
  return count;
}
