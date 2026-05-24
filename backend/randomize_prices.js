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

  // Genera un precio aleatorio entre 10 y 100 con 2 decimales para que simule Euros (e.g. 15.50, 45.99)
  const query = `
    UPDATE variantes_precios 
    SET precio_unitario = ROUND((RANDOM() * 90 + 10)::numeric, 2)
  `;

  const res = await client.query(query);
  console.log(`Se actualizaron ${res.rowCount} precios con valores aleatorios.`);

  await client.end();
}

randomize().catch(err => console.error(err));
