package com.askhub.api;

import com.askhub.dao.VoteDAO;
import com.askhub.models.Vote;
import io.javalin.Javalin;
import io.javalin.http.Handler;

public class VoteApi {
    private static final VoteDAO voteDAO = new VoteDAO();

    public static void registerRoutes(Javalin app) {
        app.post("/api/votes", createOrToggleVote);
        app.get("/api/votes", getVoteInfo);
        app.delete("/api/votes", removeVote);
    }

    public static Handler createOrToggleVote = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        if (userHeader == null) { ctx.status(401).json("user_required"); return; }
        int userId = Integer.parseInt(userHeader);
        Vote input = ctx.bodyAsClass(Vote.class);
        if (input.getTargetType() == null || input.getTargetId() == 0 || input.getVoteType() == null) {
            ctx.status(400).json("targetType_targetId_voteType_required");
            return;
        }
        input.setUserId(userId);
        boolean ok = voteDAO.vote(input);
        if (ok) {
            int count = voteDAO.getVoteCount(input.getTargetType(), input.getTargetId());
            ctx.json(new Object(){ public int voteCount = count; });
        } else ctx.status(500).json("vote_failed");
    };

    public static Handler getVoteInfo = ctx -> {
        String targetType = ctx.queryParam("targetType");
        Integer targetId = ctx.queryParamAsClass("targetId", Integer.class).getOrDefault(null);
        if (targetType == null || targetId == null) { ctx.status(400).json("targetType_and_targetId_required"); return; }
        int count = voteDAO.getVoteCount(targetType, targetId);
        Object resp = new Object(){ public int voteCount = count; };
        String userHeader = ctx.header("X-User-Id");
        if (userHeader != null) {
            int userId = Integer.parseInt(userHeader);
            Vote v = voteDAO.findVote(userId, targetType, targetId);
            resp = new Object(){ public int voteCount = count; public String myVote = v != null ? v.getVoteType() : null; };
        }
        ctx.json(resp);
    };

    public static Handler removeVote = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        if (userHeader == null) { ctx.status(401).json("user_required"); return; }
        int userId = Integer.parseInt(userHeader);
        String targetType = ctx.queryParam("targetType");
        Integer targetId = ctx.queryParamAsClass("targetId", Integer.class).getOrDefault(null);
        if (targetType == null || targetId == null) { ctx.status(400).json("targetType_and_targetId_required"); return; }
        Vote existing = voteDAO.findVote(userId, targetType, targetId);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        // Calling vote() with same voteType will remove it according to VoteDAO logic
        boolean ok = voteDAO.vote(new Vote(userId, targetType, targetId, existing.getVoteType()));
        if (ok) ctx.status(204); else ctx.status(500).json("remove_failed");
    };
}
