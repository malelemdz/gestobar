const { Client } = require('pg');

async function test() {
  const client = new Client({
    host: 'localhost', port: 5434, user: 'gestouser', password: 'gestopassword', database: 'gestobar'
  });
  await client.connect();
  const {rows} = await client.query("SELECT precio_unitario, pg_typeof(precio_unitario) as tipo FROM variantes_precios LIMIT 1");
  console.log("Raw from Postgres:", rows[0]);
  console.log("ParseFloat hace esto:", parseFloat(rows[0].precio_unitario));
  await client.end();
}
test().catch(console.log);
