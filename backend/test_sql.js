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

  console.log("Antes de la multiplicacion:");
  const antes = await client.query('SELECT vp.id, vp.precio_unitario FROM variantes_precios vp JOIN variantes v ON vp.variante_id = v.id JOIN productos p ON p.id = v.producto_id WHERE p.bar_id = $1 LIMIT 3', [id]);
  console.table(antes.rows);

  const res = await client.query(
    `UPDATE variantes_precios vp
     SET precio_unitario = vp.precio_unitario * 1000
     FROM variantes v
     JOIN productos p ON p.id = v.producto_id
     WHERE v.id = vp.variante_id AND p.bar_id = $1`,
    [id]
  );
  console.log('Filas afectadas:', res.rowCount);

  console.log("Despues de la multiplicacion:");
  const despues = await client.query('SELECT vp.id, vp.precio_unitario FROM variantes_precios vp JOIN variantes v ON vp.variante_id = v.id JOIN productos p ON p.id = v.producto_id WHERE p.bar_id = $1 LIMIT 3', [id]);
  console.table(despues.rows);

  await client.end();
}

check().catch(console.error);
