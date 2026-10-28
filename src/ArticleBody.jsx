import React from 'react';
import {parseArticleBody} from './articleIllustrations';

export default function ArticleBody({body}) {
  return parseArticleBody(body).map((block, i) => block.type === 'image'
    ? <figure className="article-illustration" key={i}>
        <img src={block.src} alt={block.alt} loading="lazy" decoding="async"/>
        {block.caption && <figcaption>{block.caption}</figcaption>}
      </figure>
    : <p key={i}>{block.text}</p>);
}
