import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { pool } from "./client.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function seed() {
  const seedPath = path.join(__dirname, "seed.sql");
  const sql = fs.readFileSync(seedPath, "utf-8");

  console.log("[seed] Inserting seed data...");
  await pool.query(sql);
  console.log("[seed] Seed data inserted successfully.");

  await pool.end();
}

seed().catch((err) => {
  console.error("[seed] Failed:", err.message);
  process.exit(1);
});
