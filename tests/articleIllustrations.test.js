import test from 'node:test';
import assert from 'node:assert/strict';
import {parseArticleBody,formatImageBlock,insertImageAtCursor} from '../src/articleIllustrations.js';

test('conserva párrafos existentes',()=>{
  assert.deepEqual(parseArticleBody('Uno\n\nDos'),[{type:'paragraph',text:'Uno'},{type:'paragraph',text:'Dos'}]);
  assert.equal(parseArticleBody(['Uno','Dos']).length,2);
});
test('interpreta imagen en el cuerpo con pie',()=>{
  const text='Antes\n\n![Mapa regional](https://ejemplo.com/mapa.webp)\n> Fuente: Archivo\n\nDespués';
  const blocks=parseArticleBody(text);
  assert.equal(blocks.length,3);
  assert.deepEqual(blocks[1],{type:'image',src:'https://ejemplo.com/mapa.webp',alt:'Mapa regional',caption:'Fuente: Archivo'});
});
test('no interpreta protocolos peligrosos como imágenes',()=>{
  assert.equal(parseArticleBody('![x](javascript:alert(1))')[0].type,'paragraph');
  assert.equal(parseArticleBody('![x](https://example.com/img.png)\nTexto normal')[0].type,'paragraph');
});
test('inserta imagen sin perder texto anterior o posterior',()=>{
  const block=formatImageBlock('https://ejemplo.com/foto.png','Foto institucional','Crédito: LMC');
  const result=insertImageAtCursor('Primero\n\nSegundo',block,7,7);
  assert.deepEqual(parseArticleBody(result.text).map(x=>x.type),['paragraph','image','paragraph']);
  assert.match(result.text,/Primero/);
  assert.match(result.text,/Segundo/);
});
test('exige descripción y esquema de URL válido',()=>{
  assert.throws(()=>formatImageBlock('javascript:alert(1)','A'),/HTTP/);
  assert.throws(()=>formatImageBlock('https://ejemplo.com/a.png',''),/descripción/);
});
