export const navigation = ['Inicio', 'Publicaciones', 'Internacional', 'Autores'];
export const articleCategories = ['Actualidad', 'Análisis', 'Opinión', 'Informes'];
export const themes = ['Política nacional', 'Internacional', 'Economía', 'Sociedad', 'Regional', 'Otra'];
export const categoryOf = article => articleCategories.includes(article.section) ? article.section : article.section === 'Ideas' ? 'Opinión' : 'Actualidad';
export const themeOf = article => article.theme || (article.section === 'Internacional' ? 'Internacional' : 'Política nacional');
export function selectArticles(articles, { section = 'Publicaciones', category = 'Todas', query = '' } = {}) {
 const term = query.trim().toLocaleLowerCase('es');
 return articles.filter(a => (section !== 'Internacional' || themeOf(a) === 'Internacional') && (category === 'Todas' || categoryOf(a) === category) && (!term || [a.title, a.deck, a.topic, a.author, categoryOf(a), themeOf(a)].join(' ').toLocaleLowerCase('es').includes(term)));
}
export function frontPage(articles) {
 const hero = articles.find(a => a.featured) || articles[0];
 const sidebar = articles.filter(a => a.id !== hero?.id).slice(0, 2);
 const used = new Set([hero?.id, ...sidebar.map(a => a.id)]);
 return { hero, sidebar, latest: articles.filter(a => !used.has(a.id)) };
}
