package com.askhub.api;

import com.askhub.dao.AnswerDAO;
import com.askhub.dao.CommentDAO;
import com.askhub.dao.QuestionDAO;
import com.askhub.models.Answer;
import com.askhub.models.Comment;
import com.askhub.models.Question;
import io.javalin.Javalin;
import io.javalin.http.Handler;

import java.util.List;

public class QuestionApi {
    private static final QuestionDAO questionDAO = new QuestionDAO();
    private static final AnswerDAO answerDAO = new AnswerDAO();
    private static final CommentDAO commentDAO = new CommentDAO();

    public static void registerRoutes(Javalin app) {
        app.post("/api/questions", createQuestion);
        app.get("/api/questions", listQuestions);
        app.get("/api/questions/{id}", getQuestion);
        app.put("/api/questions/{id}", updateQuestion);
        app.delete("/api/questions/{id}", deleteQuestion);
        app.post("/api/questions/{id}/status", changeStatus);
    }

    public static Handler createQuestion = ctx -> {
        String userIdHeader = ctx.header("X-User-Id");
        if (userIdHeader == null) { ctx.status(401).json("user_required"); return; }
        int userId = Integer.parseInt(userIdHeader);
        Question input = ctx.bodyAsClass(Question.class);
        if (input.getTopicId() == 0 || input.getTitle() == null || input.getContent() == null) {
            ctx.status(400).json("topic_title_content_required");
            return;
        }
        input.setUserId(userId);
        boolean ok = questionDAO.createQuestion(input);
        if (ok) ctx.status(201).json(input);
        else ctx.status(500).json("create_failed");
    };

    public static Handler listQuestions = ctx -> {
        String search = ctx.queryParam("search");
        Integer topicId = ctx.queryParamAsClass("topicId", Integer.class).getOrDefault(null);
        int page = ctx.queryParamAsClass("page", Integer.class).getOrDefault(1);
        int pageSize = ctx.queryParamAsClass("pageSize", Integer.class).getOrDefault(20);
        if (search != null && !search.isEmpty()) {
            ctx.json(questionDAO.searchQuestions(search, page, pageSize));
            return;
        }
        if (topicId != null) {
            ctx.json(questionDAO.getQuestionsByTopic(topicId, page, pageSize));
            return;
        }
        ctx.json(questionDAO.getAllQuestions(page, pageSize));
    };

    public static Handler getQuestion = ctx -> {
        int id = Integer.parseInt(ctx.pathParam("id"));
        Question q = questionDAO.findById(id);
        if (q == null) { ctx.status(404).json("not_found"); return; }
        // increment view count
        questionDAO.incrementViewCount(id);
        // get answers and comments
        List<Answer> answers = answerDAO.getAnswersByQuestion(id);
        List<Comment> comments = commentDAO.getCommentsByTarget("QUESTION", id);
        ctx.json(new Object(){ public Question question = q; public List<Answer> answers = answers; public List<Comment> comments = comments; });
    };

    public static Handler updateQuestion = ctx -> {
        String userIdHeader = ctx.header("X-User-Id");
        boolean isAdmin = "true".equalsIgnoreCase(ctx.header("X-Admin"));
        if (userIdHeader == null && !isAdmin) { ctx.status(401).json("user_required"); return; }
        int userId = userIdHeader != null ? Integer.parseInt(userIdHeader) : -1;
        int id = Integer.parseInt(ctx.pathParam("id"));
        Question existing = questionDAO.findById(id);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        if (!isAdmin && existing.getUserId() != userId) { ctx.status(403).json("forbidden"); return; }
        Question input = ctx.bodyAsClass(Question.class);
        existing.setTitle(input.getTitle() != null ? input.getTitle() : existing.getTitle());
        existing.setContent(input.getContent() != null ? input.getContent() : existing.getContent());
        boolean ok = questionDAO.updateQuestion(existing);
        if (ok) ctx.json(existing);
        else ctx.status(500).json("update_failed");
    };

    public static Handler deleteQuestion = ctx -> {
        String userIdHeader = ctx.header("X-User-Id");
        boolean isAdmin = "true".equalsIgnoreCase(ctx.header("X-Admin"));
        if (userIdHeader == null && !isAdmin) { ctx.status(401).json("user_required"); return; }
        int userId = userIdHeader != null ? Integer.parseInt(userIdHeader) : -1;
        int id = Integer.parseInt(ctx.pathParam("id"));
        Question existing = questionDAO.findById(id);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        if (!isAdmin && existing.getUserId() != userId) { ctx.status(403).json("forbidden"); return; }
        boolean ok = questionDAO.deleteQuestion(id);
        if (ok) ctx.status(204);
        else ctx.status(500).json("delete_failed");
    };

    public static Handler changeStatus = ctx -> {
        String userIdHeader = ctx.header("X-User-Id");
        boolean isAdmin = "true".equalsIgnoreCase(ctx.header("X-Admin"));
        if (userIdHeader == null && !isAdmin) { ctx.status(401).json("user_required"); return; }
        int userId = userIdHeader != null ? Integer.parseInt(userIdHeader) : -1;
        int id = Integer.parseInt(ctx.pathParam("id"));
        Question existing = questionDAO.findById(id);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        // Only admin or author can change status
        if (!isAdmin && existing.getUserId() != userId) { ctx.status(403).json("forbidden"); return; }
        StatusRequest req = ctx.bodyAsClass(StatusRequest.class);
        if (req == null || req.status == null) { ctx.status(400).json("status_required"); return; }
        boolean ok = questionDAO.updateStatus(id, req.status);
        if (ok) ctx.json("ok"); else ctx.status(500).json("update_failed");
    };

    public static class StatusRequest { public String status; }
}
