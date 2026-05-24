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
  
  // Forzaremos que el primer precio sea 27420 y el segundo 70000
  await client.query(
    `UPDATE variantes_precios vp
     SET precio_unitario = 27420.00
     FROM variantes v JOIN productos p ON p.id = v.producto_id
     WHERE v.id = vp.variante_id AND p.bar_id = $1 AND p.nombre = 'Fernet Branca'`,
    [id]
  );
  
  await client.query(
    `UPDATE variantes_precios vp
     SET precio_unitario = 70000.00
     FROM variantes v JOIN productos p ON p.id = v.producto_id
     WHERE v.id = vp.variante_id AND p.bar_id = $1 AND p.nombre != 'Fernet Branca'`,
    [id]
  );
  
  console.log('¡Precios inyectados masivamente a miles!');
  await client.end();
}

fix().catch(console.error);
