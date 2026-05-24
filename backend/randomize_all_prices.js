const { Client } = require('pg');

async function randomize() {
  const client = new Client({
    host: 'localhost',
    port: 5434,
    user: 'gestouser',
    password: 'gestopassword',
    database: 'gestobar'
  });

  await client.connect();

  // Obtener todas las variantes y todas las tarifas
  const { rows: variants } = await client.query('SELECT id FROM variantes');
  const { rows: tarifas } = await client.query('SELECT id FROM tarifas');
  
  let countInserted = 0;
  let countUpdated = 0;

  for (const variant of variants) {
    for (const tarifa of tarifas) {
      // Precio aleatorio
      const price = (Math.random() * 90 + 10).toFixed(2);
      
      // Buscar si ya existe el precio
      const check = await client.query(
        'SELECT id FROM variantes_precios WHERE variante_id = $1 AND tarifa_id = $2',
        [variant.id, tarifa.id]
      );
      
      if (check.rows.length > 0) {
        await client.query(
          'UPDATE variantes_precios SET precio_unitario = $1 WHERE id = $2',
          [price, check.rows[0].id]
        );
        countUpdated++;
      } else {
        await client.query(
          'INSERT INTO variantes_precios (variante_id, tarifa_id, precio_unitario) VALUES ($1, $2, $3)',
          [variant.id, tarifa.id, price]
        );
        countInserted++;
      }
    }
  }

  console.log(`Se actualizaron ${countUpdated} precios y se insertaron ${countInserted} precios nuevos de forma obligatoria.`);

  await client.end();
}

randomize().catch(err => console.error(err));
