const CV_SIGNATURES = {
  pdf(buffer) {
    return buffer.length >= 5 && buffer.subarray(0, 5).toString('ascii') === '%PDF-';
  },
  doc(buffer) {
    const signature = Buffer.from([0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1]);
    return buffer.length >= signature.length && buffer.subarray(0, signature.length).equals(signature);
  },
  docx(buffer) {
    // DOCX is an Office Open XML ZIP package.
    return buffer.length >= 4 && buffer[0] === 0x50 && buffer[1] === 0x4b &&
      [0x03, 0x05, 0x07].includes(buffer[2]) && [0x04, 0x06, 0x08].includes(buffer[3]);
  }
};

function hasValidCvSignature(extension, buffer) {
  const normalizedExtension = String(extension || '').toLowerCase().replace(/^\\./, '');
  const validator = CV_SIGNATURES[normalizedExtension];
  return Boolean(Buffer.isBuffer(buffer) && validator && validator(buffer));
}

module.exports = { hasValidCvSignature };
