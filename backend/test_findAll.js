const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('./dist/app.module');
const { ProductsService } = require('./dist/products/products.service');

async function test() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const productsService = app.get(ProductsService);
  
  const products = await productsService.findAll('9e12552b-ffa8-45d2-a3d5-67a2830e4173', null, true);
  const fernet = products.find(p => p.nombre === 'Fernet Branca');
  const whisky = products.find(p => p.nombre === 'Whisky Red Label');
  
  console.log('Fernet Branca JSON completo:');
  console.log(JSON.stringify(fernet, null, 2));
  
  console.log('Whisky JSON completo:');
  console.log(JSON.stringify(whisky, null, 2));
  
  await app.close();
}
test().catch(console.log);
