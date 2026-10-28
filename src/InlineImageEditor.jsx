import React,{useRef,useState} from 'react';
import ArticleBody from './ArticleBody';
import {formatImageBlock,insertImageAtCursor} from './articleIllustrations';

export default function InlineImageEditor({initialBody='',onUpload}) {
  const [body,setBody]=useState(initialBody||'');
  const [url,setUrl]=useState('');
  const [description,setDescription]=useState('');
  const [caption,setCaption]=useState('');
  const [uploading,setUploading]=useState(false);
  const [error,setError]=useState('');
  const [preview,setPreview]=useState(false);
  const textarea=useRef(null);

  async function upload(e) {
    const file=e.target.files?.[0];
    if(!file)return;
    setUploading(true);
    setError('');
    try {
      const uploaded=await onUpload(file);
      setUrl(uploaded);
      setDescription(value=>value || file.name.replace(/\.[^.]+$/, '').replace(/[-_]/g, ' '));
    } catch(err) {
      setError(err.message || 'No se pudo subir la imagen.');
    } finally {
      setUploading(false);
      e.target.value='';
    }
  }

  function insert() {
    setError('');
    try {
      const block=formatImageBlock(url,description,caption);
      const position=textarea.current?.selectionStart ?? body.length;
      const end=textarea.current?.selectionEnd ?? position;
      const result=insertImageAtCursor(body,block,position,end);
      setBody(result.text);
      setTimeout(()=>{
        textarea.current?.focus();
        textarea.current?.setSelectionRange(result.cursor,result.cursor);
      },0);
      setUrl('');
      setDescription('');
      setCaption('');
    } catch(err) {
      setError(err.message || 'Revisá los datos de la ilustración.');
    }
  }

  return <section className="inline-image-editor">
    <label>Texto de la nota · separá párrafos con una línea en blanco
      <textarea ref={textarea} name="body" rows="18" required value={body} onChange={e=>setBody(e.target.value)}/>
    </label>
    <fieldset className="illustration-tools">
      <legend>Ilustraciones dentro de la nota</legend>
      <p>Ubicá el cursor en el texto donde querés la imagen y completá estos datos.</p>
      <div className="illustration-grid">
        <label>Subir imagen (JPG, PNG, WebP o AVIF, hasta 5 MB)
          <input type="file" accept="image/jpeg,image/png,image/webp,image/avif" disabled={uploading} onChange={upload}/>
        </label>
        <label>O pegar enlace de imagen
          <input type="url" placeholder="https://..." value={url} onChange={e=>setUrl(e.target.value)} />
        </label>
        <label>Descripción de la imagen (accesibilidad)
          <input value={description} maxLength="250" placeholder="Qué se ve en la imagen" onChange={e=>setDescription(e.target.value)}/>
        </label>
        <label>Pie de foto o fuente (opcional)
          <input value={caption} maxLength="500" placeholder="Fotografía: ... / Fuente: ..." onChange={e=>setCaption(e.target.value)}/>
        </label>
      </div>
      {uploading&&<p role="status">Subiendo imagen…</p>}
      {error&&<p className="illustration-error" role="alert">{error}</p>}
      {url&&<img className="illustration-thumbnail" src={url} alt="Vista previa de la imagen a insertar" />}
      <button className="outline" type="button" disabled={uploading||!url||!description.trim()} onClick={insert}>+ Insertar imagen en el texto</button>
      <p className="illustration-help">Podés agregar varias imágenes, moverlas o quitarlas desde el texto. La vista previa muestra cómo se verá la nota.</p>
    </fieldset>
    <button type="button" className="outline illustration-preview-toggle" aria-expanded={preview} onClick={()=>setPreview(value=>!value)}>{preview?'Ocultar vista previa':'Ver vista previa del texto'}</button>
    {preview&&<div className="article-body illustration-preview"><ArticleBody body={body}/></div>}
  </section>;
}
