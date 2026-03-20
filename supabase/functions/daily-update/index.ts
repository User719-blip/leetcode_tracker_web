import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": Deno.env.get("ALLOWED_ORIGIN") ?? "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: corsHeaders,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Missing function environment variables" }),
      { status: 500, headers: corsHeaders }
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing authorization token" }), {
      status: 401,
      headers: corsHeaders,
    });
  }

  const accessToken = authHeader.startsWith("Bearer ")
    ? authHeader.slice(7)
    : authHeader;
  if (!accessToken) {
    return new Response(JSON.stringify({ error: "Invalid authorization token" }), {
      status: 401,
      headers: corsHeaders,
    });
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey);

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser(accessToken);

  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized user" }), {
      status: 401,
      headers: corsHeaders,
    });
  }

  const allowedAdminEmails = (Deno.env.get("ADMIN_EMAILS") ?? "")
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter((email) => email.length > 0);

  const userEmail = user.email?.toLowerCase() ?? "";
  if (!allowedAdminEmails.includes(userEmail)) {
    return new Response(
      JSON.stringify({ error: "Forbidden: admin access required" }),
      {
        status: 403,
        headers: corsHeaders,
      }
    );
  }

  console.log("[daily-update] Cron job started");

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: users, error: usersError } = await supabase
    .from("users")
    .select("*");

  if (usersError) {
    console.error("[daily-update] Error fetching users:", usersError.message);
    return new Response(JSON.stringify({ error: usersError.message }), {
      status: 500,
      headers: corsHeaders,
    });
  }

  if (!users || users.length === 0) {
    console.log("[daily-update] No users to update");
    return new Response(JSON.stringify({ message: "No users to update" }), {
      headers: corsHeaders,
    });
  }

  console.log(`[daily-update] Found ${users.length} users to update`);
  let successCount = 0;
  let errorCount = 0;

  for (const user of users) {
    try {
      console.log(`[daily-update] Fetching stats for ${user.username}`);

      let response: Response;
      try {
        response = await fetch("https://leetcode.com/graphql", {
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
      } catch (fetchErr) {
        console.error(`[daily-update] ✗ Network error for ${user.username}: ${fetchErr.message}`);
        errorCount++;
        continue;
      }

      if (!response.ok) {
        console.error(`[daily-update] ✗ LeetCode API returned HTTP ${response.status} for ${user.username}`);
        errorCount++;
        continue;
      }

      let result: any;
      try {
        result = await response.json();
      } catch (parseErr) {
        console.error(`[daily-update] ✗ Failed to parse JSON response for ${user.username}: ${parseErr.message}`);
        errorCount++;
        continue;
      }

      if (result?.errors?.length) {
        const apiErrors = result.errors.map((e: any) => e.message).join(", ");
        console.error(`[daily-update] ✗ LeetCode GraphQL errors for ${user.username}: ${apiErrors}`);
        errorCount++;
        continue;
      }

      const matchedUser = result?.data?.matchedUser;
      if (!matchedUser) {
        console.warn(`[daily-update] ✗ User not found on LeetCode: ${user.username} (username may be wrong or account deleted)`);
        errorCount++;
        continue;
      }

      const stats = matchedUser.submitStats?.acSubmissionNum ?? [];

      let easy = 0, medium = 0, hard = 0, total = 0;

      for (const s of stats) {
        if (s.difficulty === "Easy") easy = s.count;
        if (s.difficulty === "Medium") medium = s.count;
        if (s.difficulty === "Hard") hard = s.count;
        if (s.difficulty === "All") total = s.count;
      }

      const ranking = matchedUser.profile?.ranking ?? 0;

      const { error: upsertError } = await supabase.from("snapshots").upsert({
        user_id: user.id,
        date: new Date().toISOString().split("T")[0],
        easy,
        medium,
        hard,
        total,
        ranking
      });

      if (upsertError) {
        console.error(`[daily-update] Upsert error for ${user.username}:`, upsertError.message);
        errorCount++;
      } else {
        console.log(`[daily-update] ✓ Upserted ${user.username}: total=${total}, ranking=${ranking}`);
        successCount++;
      }
    } catch (err) {
      console.error(`[daily-update] Exception for ${user.username}:`, err.message);
      errorCount++;
    }
  }

  console.log(`[daily-update] Completed: ${successCount} successful, ${errorCount} errors`);
  return new Response(
    JSON.stringify({ message: "Stats updated", successCount, errorCount }),
    { headers: corsHeaders }
  );
});