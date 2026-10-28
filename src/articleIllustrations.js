// Formato sencillo para imágenes entre párrafos: ![Descripción](https://imagen)
 // Pie opcional en la línea siguiente: > Texto del pie
export function parseArticleBody(value) {
  const text = Array.isArray(value) ? value.join('\n\n') : String(value || '');
  return text.split(/\n\s*\n/).map(part => part.trim()).filter(Boolean).map(part => {
    const lines = part.split('\n');
    const image = /^!\[([^\]\n]*)\]\((https?:\/\/[^\s)]+)\)$/.exec(lines[0].trim());
    const captionLine = lines.length === 2 ? /^>\s*(.*)$/.exec(lines[1].trim()) : null;
    if (image && (lines.length === 1 || captionLine)) {
      try {
        const url = new URL(image[2]);
        if (url.protocol === 'https:' || url.protocol === 'http:') {
          return {type:'image', src:url.href, alt:image[1], caption:captionLine?.[1] || ''};
        }
      } catch {}
    }
    return {type:'paragraph', text:part};
  });
}

export function formatImageBlock(url, description, caption = '') {
  const parsed = new URL(String(url || '').trim());
  if (!['https:', 'http:'].includes(parsed.protocol)) throw Error('La imagen debe tener un enlace HTTP o HTTPS.');
  const alt = String(description || '').replace(/[\[\]\r\n]/g, ' ').trim();
  if (!alt) throw Error('Agregá una descripción de la imagen.');
  const cleanCaption = String(caption || '').replace(/\s+/g, ' ').trim();
  return '![' + alt + '](' + parsed.href.replace(/\)/g, '%29') + ')' + (cleanCaption ? '\n> ' + cleanCaption : '');
}

export function insertImageAtCursor(body, imageBlock, start, end = start) {
  const text = String(body || '');
  const from = Math.max(0, Math.min(text.length, Number(start) || 0));
  const to = Math.max(from, Math.min(text.length, Number(end) || from));
  const before = text.slice(0, from).replace(/[ \t]*$/, '');
  const after = text.slice(to).replace(/^[ \t]*/, '');
  const prefix = before && !before.endsWith('\n\n') ? (before.endsWith('\n') ? '\n' : '\n\n') : '';
  const suffix = after && !after.startsWith('\n\n') ? (after.startsWith('\n') ? '\n' : '\n\n') : '';
  return {text:before + prefix + imageBlock + suffix + after, cursor: (before + prefix + imageBlock).length};
}
