export function buildThreads(comments){
 const nodes=new Map(comments.map(c=>[c.id,{...c,replies:[]}]));
 const roots=[];
 for(const c of comments){const node=nodes.get(c.id),parent=nodes.get(c.parent_id);if(parent&&parent!==node)parent.replies.push(node);else roots.push(node)}
 return roots;
}
export const previewItems=(items,expanded)=>expanded?items:items.slice(0,3);
