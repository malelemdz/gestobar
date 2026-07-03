const { Client } = require('pg');

async function check() {
  const client = new Client({
    host: 'localhost',
    port: 5434,
    user: 'gestouser',
    password: 'gestopassword',
    database: 'gestobar'
  });

  await client.connect();

  console.log("LAST 5 SALES:");
  const sales = await client.query('SELECT id, fecha, total FROM ventas ORDER BY fecha DESC LIMIT 5');
  console.table(sales.rows);

  console.log("AUDITORIA COLUMNS:");
  const cols = await client.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'auditoria'");
  console.log(cols.rows.map(c => c.column_name));

  console.log("LAST 5 AUDITORIA ENTRIES:");
  const logs = await client.query('SELECT * FROM auditoria ORDER BY id DESC LIMIT 5');
  console.table(logs.rows.map(r => ({
    id: r.id,
    updated_at: r.updated_at,
    accion: r.accion,
    detalles: JSON.stringify(r.detalles)
  })));

  await client.end();
}

check().catch(console.error);
