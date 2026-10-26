export const hasAuthor=(article,id)=>article.author_id===id||article.coauthor_id===id;
export function authorCredits(article,authors){
 const primary=authors.find(a=>a.id===article.author_id);
 const secondary=authors.find(a=>a.id===article.coauthor_id);
 return [primary||{name:article.author||'Equipo editorial'},secondary].filter(Boolean);
}
