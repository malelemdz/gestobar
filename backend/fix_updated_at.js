const { Client } = require('pg');

async function test() {
  const client = new Client({
    host: 'localhost', port: 5434, user: 'gestouser', password: 'gestopassword', database: 'gestobar'
  });
  await client.connect();
  const res = await client.query(`
    UPDATE productos 
    SET updated_at = NOW() 
    WHERE bar_id = '9e12552b-ffa8-45d2-a3d5-67a2830e4173'
  `);
  console.log('Productos tocados:', res.rowCount);
  await client.end();
}
test().catch(console.log);
