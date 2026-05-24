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
  const id = '9e12552b-ffa8-45d2-a3d5-67a2830e4173';
  
  const { rows } = await client.query('SELECT v.id as variante_id, vp.precio_unitario, p.nombre FROM variantes_precios vp JOIN variantes v ON vp.variante_id = v.id JOIN productos p ON p.id = v.producto_id WHERE p.bar_id = $1 LIMIT 10', [id]);
  console.log('--- PRECIOS REALES CRUDOS EN LA BASE DE DATOS AHORA MISMO ---');
  console.table(rows);

  await client.end();
}

check().catch(console.error);
