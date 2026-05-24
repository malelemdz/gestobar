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
  
  // Asignar precio de 27.50
  await client.query(
    `UPDATE variantes_precios vp
     SET precio_unitario = 27.50
     FROM variantes v JOIN productos p ON p.id = v.producto_id
     WHERE v.id = vp.variante_id AND p.bar_id = $1 AND p.nombre = 'Fernet Branca'`,
    [id]
  );
  
  // Asignar precio de 35.00
  await client.query(
    `UPDATE variantes_precios vp
     SET precio_unitario = 35.00
     FROM variantes v JOIN productos p ON p.id = v.producto_id
     WHERE v.id = vp.variante_id AND p.bar_id = $1 AND p.nombre = 'Whisky Red Label'`,
    [id]
  );
  
  // Asignar 15.00 al resto
  await client.query(
    `UPDATE variantes_precios vp
     SET precio_unitario = 15.00
     FROM variantes v JOIN productos p ON p.id = v.producto_id
     WHERE v.id = vp.variante_id AND p.bar_id = $1 AND p.nombre NOT IN ('Fernet Branca', 'Whisky Red Label')`,
    [id]
  );
  
  console.log('¡Precios reseteados a valores reales de Bolivia!');
  await client.end();
}

fix().catch(console.error);
