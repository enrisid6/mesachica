import React,{useEffect,useState} from 'react';
import {Eye} from 'lucide-react';
import {supabase} from './supabase';
let memorySession;
export function viewSession(){
 if(memorySession)return memorySession;
 try{const existing=sessionStorage.getItem('lmc.viewSession');if(existing&&/^[0-9a-f-]{36}$/i.test(existing))return memorySession=existing;memorySession=crypto.randomUUID();sessionStorage.setItem('lmc.viewSession',memorySession)}catch{memorySession=crypto.randomUUID()}
 return memorySession;
}
export default function ViewCount({articleId}){
 const [count,setCount]=useState(null);
 useEffect(()=>{let active=true;setCount(null);if(!supabase)return;async function track(){try{const r=await supabase.rpc('record_article_view',{p_article_id:articleId,p_session:viewSession()});if(r.error)throw r.error;if(active&&r.data!==null)setCount(Number(r.data))}catch{const r=await supabase.from('article_stats').select('views').eq('article_id',articleId).maybeSingle();if(active&&!r.error)setCount(Number(r.data?.views||0))}}track();return()=>{active=false}},[articleId]);
 return <span className="view-count" title="Aperturas aproximadas, sin repetir recargas en esta sesión"><Eye size={15} aria-hidden="true"/>{count===null?'—':count.toLocaleString('es-AR')} visualizaciones</span>;
}
