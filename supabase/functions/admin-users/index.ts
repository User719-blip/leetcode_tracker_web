import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type AdminAction = "listUsers" | "addUser" | "deleteUser";

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
      return jsonResponse(500, { error: "Missing function environment variables" });
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse(401, { error: "Missing authorization token" });
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse(401, { error: "Unauthorized user" });
    }

    const allowedAdminEmails = (Deno.env.get("ADMIN_EMAILS") ?? "")
      .split(",")
      .map((email) => email.trim().toLowerCase())
      .filter((email) => email.length > 0);

    const userEmail = user.email?.toLowerCase() ?? "";
    const isAdmin = allowedAdminEmails.includes(userEmail);

    if (!isAdmin) {
      return jsonResponse(403, { error: "Forbidden: admin access required" });
    }

    const body = await req.json();
    const action = body?.action as AdminAction | undefined;
    const payload = body?.payload ?? {};

    if (!action) {
      return jsonResponse(400, { error: "Missing action" });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    if (action === "listUsers") {
      const { data, error } = await adminClient
        .from("users")
        .select("id, username")
        .order("username", { ascending: true });

      if (error) {
        return jsonResponse(500, { error: error.message });
      }

      return jsonResponse(200, { users: data ?? [] });
    }

    if (action === "addUser") {
      const username = String(payload?.username ?? "").trim();
      if (!username) {
        return jsonResponse(400, { error: "Username is required" });
      }

      const { data, error } = await adminClient
        .from("users")
        .insert({ username })
        .select("id, username")
        .single();

      if (error) {
        return jsonResponse(500, { error: error.message });
      }

      return jsonResponse(200, { user: data });
    }

    if (action === "deleteUser") {
      const id = String(payload?.id ?? "").trim();
      if (!id) {
        return jsonResponse(400, { error: "User id is required" });
      }

      const { error } = await adminClient.from("users").delete().eq("id", id);
      if (error) {
        return jsonResponse(500, { error: error.message });
      }

      return jsonResponse(200, { success: true });
    }

    return jsonResponse(400, { error: "Invalid action" });
  } catch (error) {
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : "Unknown server error",
    });
  }
});
