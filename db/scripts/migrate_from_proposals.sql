-- Static data about the Proposals site. Leave these alone.
SET @proposals_community_id = 23;
SET @proposal_main_tag_set = 46;
SET @proposal_meta_tag_set = 47;
SET @proposals_main = 67;
SET @proposals_meta = 68;

-- Set these to the right values for the proposal topic tag.
SET @proposal_tag_id = 8367;
SET @proposal_tag_name = 'puzzles';

-- Fill these in once the new community has been created.
SET @new_community_id = 24;
SET @main_tag_set_id = 48;
SET @meta_tag_set_id = 49;
SET @new_main = 72;
SET @new_meta = 71;

SAVEPOINT before_migration;

-- Temporary tables for required profile IDs and post IDs in the proposal tag.
CREATE TEMPORARY TABLE IF NOT EXISTS profiles_to_create (user_id BIGINT, UNIQUE (user_id));
CREATE TEMPORARY TABLE IF NOT EXISTS all_posts (post_id BIGINT, UNIQUE (post_id));

TRUNCATE profiles_to_create;
TRUNCATE all_posts;

-- Fill in all_posts.
INSERT IGNORE INTO all_posts (post_id)
SELECT p.id
FROM posts p
INNER JOIN posts_tags pt ON p.id = pt.post_id
WHERE
	p.community_id = @proposals_community_id AND
	pt.tag_id = @proposal_tag_id AND
	p.closed = FALSE AND
	p.`locked` = FALSE AND
	p.deleted = FALSE;

INSERT IGNORE INTO all_posts (post_id)
SELECT p.id
FROM posts p
WHERE p.parent_id IN (
	SELECT pp.id
	FROM posts pp
	INNER JOIN posts_tags pt ON pp.id = pt.post_id
	WHERE
		pp.community_id = @proposals_community_id AND
		pt.tag_id = @proposal_tag_id
)
AND p.`locked` = FALSE
AND p.deleted = FALSE;


-- Pick out user IDs who need profiles creating on the new site.
INSERT IGNORE INTO profiles_to_create (user_id)
SELECT p.user_id
FROM posts p
WHERE
	id IN (SELECT post_id FROM all_posts);
	
INSERT IGNORE INTO profiles_to_create (user_id)
SELECT c.user_id
FROM comments c
INNER JOIN comment_threads ct ON ct.id = c.comment_thread_id
WHERE ct.post_id IN (SELECT post_id FROM all_posts);

INSERT IGNORE INTO profiles_to_create (user_id)
SELECT v.user_id
FROM votes v
WHERE v.post_id IN (SELECT post_id FROM all_posts);

INSERT IGNORE INTO profiles_to_create (user_id)
SELECT r.user_id
FROM reactions r
WHERE r.post_id IN (SELECT post_id FROM all_posts);

INSERT IGNORE INTO profiles_to_create (user_id)
SELECT f.user_id
FROM flags f
WHERE f.post_id IN (SELECT post_id FROM all_posts);

INSERT IGNORE INTO profiles_to_create (user_id)
SELECT se.user_id
FROM suggested_edits se
WHERE se.post_id IN (SELECT post_id FROM all_posts);

INSERT IGNORE INTO profiles_to_create (user_id)
SELECT ph.user_id
FROM post_histories ph
WHERE ph.post_id IN (SELECT post_id FROM all_posts);


-- Create user profiles
INSERT INTO community_users (community_id, user_id, created_at, updated_at, reputation)
SELECT
	@new_community_id,
	pc.user_id,
	CURRENT_TIMESTAMP,
	CURRENT_TIMESTAMP,
	1
FROM profiles_to_create pc;


-- Change main tags to new tag set
UPDATE tags t
SET t.tag_set_id = @main_tag_set_id
WHERE t.id IN (
	SELECT DISTINCT pt.tag_id
	FROM posts_tags pt
	WHERE pt.post_id IN (SELECT post_id FROM all_posts)
)
AND t.id != @proposal_tag_id
AND t.tag_set_id = @proposal_main_tag_set;


-- Create new meta tags.
INSERT IGNORE INTO tags t (`name`, created_at, updated_at, community_id, tag_set_id)
SELECT
	t.`name`,
	CURRENT_TIMESTAMP,
	CURRENT_TIMESTAMP,
	@new_community_id,
	@meta_tag_set_id
FROM tags t
INNER JOIN posts_tags pt ON pt.tag_id = t.id
WHERE
	pt.post_id IN (SELECT post_id FROM all_posts)
	AND t.id != @proposal_tag_id
	AND t.tag_set_id = @proposal_meta_tag_set;


-- Update posts to use new meta tags.
UPDATE posts_tags pt
INNER JOIN tags t ON pt.tag_id = t.id
SET pt.tag_id = (SELECT id FROM tags WHERE `name` = pt.`name` AND tag_set_id = @proposal_meta_tag_set)
WHERE
	pt.post_id IN (SELECT post_id FROM all_posts)
	AND t.tag_set_id = @proposal_meta_tag_set
	AND t.id != @proposal_tag_id;


-- Update post tag caches to remove proposal tag.
UPDATE posts p
INNER JOIN posts_tags pt ON p.id = pt.post_id
SET p.tags_cache = REPLACE(p.tags_cache, CONCAT('\n- ', @proposal_tag_name, '\n'), '\n')
WHERE
	p.id IN (SELECT post_id FROM all_posts)
	AND pt.tag_id = @proposal_tag_id;


-- Delete all uses of the proposal tag itself.
DELETE FROM posts_tags pt
WHERE pt.tag_id = @proposal_tag_id;


-- Move posts to new categories.
UPDATE posts p
SET
	p.category_id = @new_main,
	p.community_id = @new_community_id
WHERE
	p.id IN (SELECT post_id FROM all_posts)
	AND p.category_id = @proposals_main;
	
UPDATE posts p
SET
	p.category_id = @new_meta,
	p.community_id = @new_community_id
WHERE
	p.id IN (SELECT post_id FROM all_posts)
	AND p.category_id = @proposals_meta;
	

-- Change community for everything else.
UPDATE post_histories ph
SET ph.community_id = @new_community_id
WHERE ph.post_id IN (SELECT post_id FROM all_posts);

UPDATE suggested_edits se
SET se.community_id = @new_community_id
WHERE se.post_id IN (SELECT post_id FROM all_posts);

UPDATE comment_threads ct
SET ct.community_id = @new_community_id
WHERE ct.post_id IN (SELECT post_id FROM all_posts);

UPDATE comments c
SET c.community_id = @new_community_id
WHERE c.post_id IN (SELECT post_id FROM all_posts);

UPDATE votes v
SET v.community_id = @new_community_id
WHERE v.post_id IN (SELECT post_id FROM all_posts);


-- Delete flags and reactions - they probably don't apply any longer and copying them requires aligning type records.
DELETE FROM reactions r
WHERE r.post_id IN (SELECT post_id FROM all_posts);

DELETE FROM flags f
WHERE f.post_id IN (SELECT post_id FROM all_posts);


-- Run this script, then either RELEASE SAVEPOINT before_migration; or ROLLBACK TO SAVEPOINT before_migration;
