package com.askhub.api;

import com.askhub.dao.CommentDAO;
import com.askhub.models.Comment;
import io.javalin.Javalin;
import io.javalin.http.Handler;

import java.util.List;

public class CommentApi {
    private static final CommentDAO commentDAO = new CommentDAO();

    public static void registerRoutes(Javalin app) {
        app.post("/api/comments", createComment);
        app.get("/api/comments", listComments);
        app.put("/api/comments/{id}", updateComment);
        app.delete("/api/comments/{id}", deleteComment);
    }

    public static Handler createComment = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        if (userHeader == null) { ctx.status(401).json("user_required"); return; }
        int userId = Integer.parseInt(userHeader);
        Comment input = ctx.bodyAsClass(Comment.class);
        if (input.getTargetType() == null || input.getContent() == null) { ctx.status(400).json("target_and_content_required"); return; }
        input.setUserId(userId);
        boolean ok = commentDAO.createComment(input);
        if (ok) ctx.status(201).json(input); else ctx.status(500).json("create_failed");
    };

    public static Handler listComments = ctx -> {
        String targetType = ctx.queryParam("targetType");
        Integer targetId = ctx.queryParamAsClass("targetId", Integer.class).getOrDefault(null);
        if (targetType == null || targetId == null) { ctx.status(400).json("targetType_and_targetId_required"); return; }
        List<Comment> comments = commentDAO.getCommentsByTarget(targetType, targetId);
        ctx.json(comments);
    };

    public static Handler updateComment = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        boolean isAdmin = "true".equalsIgnoreCase(ctx.header("X-Admin"));
        if (userHeader == null && !isAdmin) { ctx.status(401).json("user_required"); return; }
        int userId = userHeader != null ? Integer.parseInt(userHeader) : -1;
        int id = Integer.parseInt(ctx.pathParam("id"));
        Comment existing = commentDAO.findById(id);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        if (!isAdmin && existing.getUserId() != userId) { ctx.status(403).json("forbidden"); return; }
        Comment input = ctx.bodyAsClass(Comment.class);
        existing.setContent(input.getContent() != null ? input.getContent() : existing.getContent());
        boolean ok = commentDAO.updateComment(existing);
        if (ok) ctx.json(existing); else ctx.status(500).json("update_failed");
    };

    public static Handler deleteComment = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        boolean isAdmin = "true".equalsIgnoreCase(ctx.header("X-Admin"));
        if (userHeader == null && !isAdmin) { ctx.status(401).json("user_required"); return; }
        int userId = userHeader != null ? Integer.parseInt(userHeader) : -1;
        int id = Integer.parseInt(ctx.pathParam("id"));
        Comment existing = commentDAO.findById(id);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        if (!isAdmin && existing.getUserId() != userId) { ctx.status(403).json("forbidden"); return; }
        boolean ok = commentDAO.deleteComment(id);
        if (ok) ctx.status(204); else ctx.status(500).json("delete_failed");
    };
}
