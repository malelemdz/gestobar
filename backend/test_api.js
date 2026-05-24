const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/menu/el-templo-del-oro', // o probar con bar_id si el slug no funciona
  method: 'GET'
};

const req = http.request(options, res => {
  let data = '';
  res.on('data', d => data += d);
  res.on('end', () => {
    try {
      const json = JSON.parse(data);
      console.log('Respuesta del Backend para el Menú Público:');
      if (json.statusCode === 404) {
         console.log('Error 404. Voy a intentar directo a base de datos...');
      } else {
         console.log(JSON.stringify(json, null, 2).substring(0, 500));
      }
    } catch(e) { console.log('No json'); }
  });
});
req.end();
