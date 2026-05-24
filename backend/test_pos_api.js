const http = require('http');

async function test() {
  // 1. Login to get token
  const loginData = JSON.stringify({
    email: 'admin@templo.com', // asumiendo que este es el correo, o si no buscaré en DB
    password: 'admin'
  });
  
  // Vamos a buscar el primer admin en la DB para iniciar sesion
  const { Client } = require('pg');
  const client = new Client({
    host: 'localhost', port: 5434, user: 'gestouser', password: 'gestopassword', database: 'gestobar'
  });
  await client.connect();
  const {rows} = await client.query("SELECT email FROM users LIMIT 1");
  await client.end();
  const email = rows[0].email;
  console.log('Usando email:', email);
  
  const loginReq = http.request({
    hostname: 'localhost', port: 3000, path: '/auth/login', method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, res => {
    let d = '';
    res.on('data', chunk => d+=chunk);
    res.on('end', () => {
      const token = JSON.parse(d).access_token;
      
      // 2. Fetch POS products
      const pReq = http.request({
        hostname: 'localhost', port: 3000, path: '/products?barId=9e12552b-ffa8-45d2-a3d5-67a2830e4173', method: 'GET',
        headers: { 'Authorization': 'Bearer ' + token }
      }, res2 => {
        let pD = '';
        res2.on('data', chunk => pD+=chunk);
        res2.on('end', () => {
          const prods = JSON.parse(pD);
          const f = prods.find(p => p.nombre === 'Fernet Branca');
          if(f) console.log(JSON.stringify(f.variantes, null, 2));
        });
      });
      pReq.end();
    });
  });
  loginReq.write(JSON.stringify({email, password: 'password123'})); // Password por defecto del seed?
  loginReq.end();
}
test().catch(console.log);
