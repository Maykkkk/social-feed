-- 3. Enable RLS and add policies
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anon read posts"
ON posts
FOR SELECT
USING (auth.role() = 'anon');

ALTER TABLE user_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anon read user_likes"
ON user_likes
FOR SELECT
USING (auth.role() = 'anon');

CREATE POLICY "Allow anon insert user_likes"
ON user_likes
FOR INSERT
WITH CHECK (auth.role() = 'anon');

CREATE POLICY "Allow anon delete user_likes"
ON user_likes
FOR DELETE
USING (auth.role() = 'anon');

CREATE POLICY "Allow anon update posts"
ON posts
FOR UPDATE
WITH CHECK (auth.role() = 'anon');
