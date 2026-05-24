const http = require('http');

// Vamos a revisar qué devuelve la API directamente ahora mismo para Fernet Branca
const req = http.request('http://localhost:3000/menu/templo-oro/productos', res => {
  let data = '';
  res.on('data', d => data += d);
  res.on('end', () => {
    const json = JSON.parse(data);
    const fernet = json.find(c => c.productos.some(p => p.nombre === 'Fernet Branca'));
    if (fernet) {
       const prod = fernet.productos.find(p => p.nombre === 'Fernet Branca');
       console.log('El API del servidor está devolviendo el precio:', prod.variantes[0].precio);
    }
  });
});
req.end();
