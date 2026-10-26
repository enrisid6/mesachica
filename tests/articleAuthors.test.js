import test from 'node:test';
import assert from 'node:assert/strict';
import {hasAuthor,authorCredits} from '../src/articleAuthors.js';
const authors=[{id:'a',name:'Ana'},{id:'b',name:'Bruno'}];
test('shared note appears in both profiles with separate credits',()=>{const p={author_id:'a',coauthor_id:'b',author:'Ana'};assert.ok(hasAuthor(p,'a'));assert.ok(hasAuthor(p,'b'));assert.equal(hasAuthor(p,'c'),false);assert.deepEqual(authorCredits(p,authors).map(a=>a.name),['Ana','Bruno']);});
test('legacy signature and current profile names remain supported',()=>{assert.deepEqual(authorCredits({author:'Equipo'},authors),[{name:'Equipo'}]);assert.equal(authorCredits({author_id:'a',author:'Old'},authors)[0].name,'Ana');assert.equal(authorCredits({author_id:'a',coauthor_id:'deleted'},authors).length,1);});
