import pkg from 'pg';
const { Client } = pkg;

async function reset() {
  if (!process.env.DATABASE_URL) {
    console.log("No DATABASE_URL found. Skipping reset.");
    return;
  }

  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log("Connected to database. Starting reset...");
    
    await client.query(`
      DROP SCHEMA public CASCADE;
      CREATE SCHEMA public;
      GRANT ALL ON SCHEMA public TO public;
    `);
    
    console.log("Database reset successful. All tables dropped.");
  } catch (err) {
    console.error("Error resetting database:", err);
  } finally {
    await client.end();
  }
}

reset();
