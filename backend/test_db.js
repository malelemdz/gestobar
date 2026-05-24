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

  const { rows } = await client.query('SELECT vp.id, vp.precio_unitario, v.producto_id, p.bar_id FROM variantes_precios vp JOIN variantes v ON vp.variante_id = v.id JOIN productos p ON p.id = v.producto_id LIMIT 5');
  console.log('Precios actuales en DB:');
  console.table(rows);

  await client.end();
}

check().catch(console.error);
