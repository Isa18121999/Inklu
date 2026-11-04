const test = require('node:test');
const assert = require('node:assert/strict');
const { hasValidCvSignature } = require('../services/file-validation');

test('acepta firmas PDF, DOC y DOCX según su extensión', () => {
  const pdf = Buffer.from('%PDF-1.7 contenido');
  const doc = Buffer.from([0xd0,0xcf,0x11,0xe0,0xa1,0xb1,0x1a,0xe1,0x00]);
  const docx = Buffer.from([0x50,0x4b,0x03,0x04,0x00]);
  assert.equal(hasValidCvSignature('pdf', pdf), true);
  assert.equal(hasValidCvSignature('doc', doc), true);
  assert.equal(hasValidCvSignature('docx', docx), true);
});

test('rechaza extensiones no admitidas y contenido que no coincide', () => {
  const pdf = Buffer.from('%PDF-1.7 contenido');
  assert.equal(hasValidCvSignature('docx', pdf), false);
  assert.equal(hasValidCvSignature('exe', pdf), false);
  assert.equal(hasValidCvSignature('pdf', Buffer.from('texto cualquiera')), false);
  assert.equal(hasValidCvSignature('pdf', null), false);
});
