import pg from "pg";
import { config } from "../config.js";

const pool = new pg.Pool({ connectionString: config.db.url });

pool.on("error", (err) => {
  console.error("[db] Unexpected pool error:", err.message);
});

export async function query<T extends pg.QueryResultRow = any>(
  text: string,
  params?: unknown[]
): Promise<pg.QueryResult<T>> {
  return pool.query<T>(text, params);
}

export async function getClient(): Promise<pg.PoolClient> {
  return pool.connect();
}

export async function shutdown(): Promise<void> {
  await pool.end();
}

export { pool };
