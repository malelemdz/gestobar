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

  // Create a temp table to test exactly what happens
  await client.query(`CREATE TEMP TABLE test_precios (precio_unitario DECIMAL(12, 2))`);
  await client.query(`INSERT INTO test_precios (precio_unitario) VALUES (27.42)`);
  await client.query(`UPDATE test_precios SET precio_unitario = precio_unitario * 1000`);
  
  const { rows } = await client.query('SELECT * FROM test_precios');
  console.log('Resultado de 27.42 * 1000 en Postgres DECIMAL(12, 2):');
  console.table(rows);

  await client.end();
}

check().catch(console.error);
