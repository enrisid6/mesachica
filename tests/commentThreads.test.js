import test from 'node:test';
import assert from 'node:assert/strict';
import {buildThreads,previewItems} from '../src/commentThreads.js';
test('replies remain in their parent thread, including nested replies',()=>{const t=buildThreads([{id:'a'},{id:'b'},{id:'r',parent_id:'a'},{id:'rr',parent_id:'r'}]);assert.equal(t.length,2);assert.equal(t[0].replies[0].replies[0].id,'rr')});
test('show complete reveals more than three without losing comments',()=>{const a=[1,2,3,4,5];assert.deepEqual(previewItems(a,false),[1,2,3]);assert.deepEqual(previewItems(a,true),a)});
test('replies survive a deleted parent and become root comments',()=>{assert.equal(buildThreads([{id:'reply',parent_id:null}])[0].id,'reply')});
