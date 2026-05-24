const { Client } = require('pg');

async function fix() {
  const client = new Client({
    host: 'localhost',
    port: 5434,
    user: 'gestouser',
    password: 'gestopassword',
    database: 'gestobar'
  });
  await client.connect();
  const id = '9e12552b-ffa8-45d2-a3d5-67a2830e4173';
  await client.query(
    `UPDATE variantes_precios vp
     SET precio_unitario = vp.precio_unitario / 1000
     FROM variantes v
     JOIN productos p ON p.id = v.producto_id
     WHERE v.id = vp.variante_id AND p.bar_id = $1`,
    [id]
  );
  console.log('Restaurados los precios a la normalidad.');
  await client.end();
}

fix().catch(console.error);
