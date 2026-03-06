import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { pool } from "./client.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function migrate() {
  const schemaPath = path.join(__dirname, "schema.sql");
  const sql = fs.readFileSync(schemaPath, "utf-8");

  console.log("[migrate] Applying schema...");
  await pool.query(sql);
  console.log("[migrate] Schema applied successfully.");

  await pool.end();
}

migrate().catch((err) => {
  console.error("[migrate] Failed:", err.message);
  process.exit(1);
});
