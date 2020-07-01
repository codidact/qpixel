create view tags_paths as
WITH RECURSIVE tag_path (id, created_at, updated_at, community_id, tag_set_id, wiki_markdown,
                         wiki, excerpt, parent_id, name, path) AS
                   (
                       SELECT id, created_at, updated_at, community_id, tag_set_id, wiki_markdown,
                              wiki, excerpt, parent_id, name, name as path
                       FROM tags
                       WHERE parent_id IS NULL
                       UNION ALL
                       SELECT t.id, t.created_at, t.updated_at, t.community_id, t.tag_set_id, t.wiki_markdown,
                              t.wiki, t.excerpt, t.parent_id, t.name, concat(tp.path, ' > ', t.name) as path
                       FROM tag_path AS tp JOIN tags AS t ON tp.id = t.parent_id
                   )
SELECT * FROM tag_path
ORDER BY path;