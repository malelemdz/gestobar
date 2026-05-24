const { Client } = require('pg');

async function test() {
  const client = new Client({
    host: 'localhost', port: 5434, user: 'gestouser', password: 'gestopassword', database: 'gestobar'
  });
  await client.connect();
  await client.query(`
    UPDATE variantes 
    SET updated_at = NOW() 
    WHERE producto_id IN (SELECT id FROM productos WHERE bar_id = '9e12552b-ffa8-45d2-a3d5-67a2830e4173')
  `);
  console.log('Fechas de variantes arregladas');
  await client.end();
}
test().catch(console.log);
