import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "*",
};

Deno.serve(async () => {

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { data: users } = await supabase
    .from("users")
    .select("*");

  for (const user of users) {

    const response = await fetch("https://leetcode.com/graphql", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Referer": "https://leetcode.com"
      },
      body: JSON.stringify({
        query: `
        query getUserProfile($username: String!) {
          matchedUser(username: $username) {
            submitStats {
              acSubmissionNum {
                difficulty
                count
              }
            }
            profile {
              ranking
            }
          }
        }`,
        variables: { username: user.username }
      }),
    });

    const result = await response.json();

    const stats = result.data.matchedUser.submitStats.acSubmissionNum;

    let easy = 0, medium = 0, hard = 0, total = 0;

    for (const s of stats) {
      if (s.difficulty === "Easy") easy = s.count;
      if (s.difficulty === "Medium") medium = s.count;
      if (s.difficulty === "Hard") hard = s.count;
      if (s.difficulty === "All") total = s.count;
    }

    const ranking = result.data.matchedUser.profile.ranking;

    await supabase.from("snapshots").upsert({
      user_id: user.id,
      date: new Date().toISOString().split("T")[0],
      easy,
      medium,
      hard,
      total,
      ranking
    });
  }

  return new Response(
    JSON.stringify({ message: "Stats updated" }),
    { headers: corsHeaders }
  );
});