package com.askhub.api;

import com.askhub.dao.AnswerDAO;
import com.askhub.dao.QuestionDAO;
import com.askhub.models.Answer;
import com.askhub.models.Question;
import io.javalin.Javalin;
import io.javalin.http.Handler;

import java.util.List;

public class AnswerApi {
    private static final AnswerDAO answerDAO = new AnswerDAO();
    private static final QuestionDAO questionDAO = new QuestionDAO();

    public static void registerRoutes(Javalin app) {
        app.post("/api/questions/{id}/answers", createAnswer);
        app.get("/api/questions/{id}/answers", listAnswers);
        app.put("/api/answers/{id}", updateAnswer);
        app.delete("/api/answers/{id}", deleteAnswer);
        app.post("/api/answers/{id}/accept", acceptAnswer);
    }

    public static Handler createAnswer = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        if (userHeader == null) { ctx.status(401).json("user_required"); return; }
        int userId = Integer.parseInt(userHeader);
        int questionId = Integer.parseInt(ctx.pathParam("id"));
        Answer input = ctx.bodyAsClass(Answer.class);
        if (input.getContent() == null || input.getContent().trim().isEmpty()) {
            ctx.status(400).json("content_required");
            return;
        }
        input.setQuestionId(questionId);
        input.setUserId(userId);
        boolean ok = answerDAO.createAnswer(input);
        if (ok) ctx.status(201).json(input);
        else ctx.status(500).json("create_failed");
    };

    public static Handler listAnswers = ctx -> {
        int questionId = Integer.parseInt(ctx.pathParam("id"));
        List<Answer> answers = answerDAO.getAnswersByQuestion(questionId);
        ctx.json(answers);
    };

    public static Handler updateAnswer = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        boolean isAdmin = "true".equalsIgnoreCase(ctx.header("X-Admin"));
        if (userHeader == null && !isAdmin) { ctx.status(401).json("user_required"); return; }
        int userId = userHeader != null ? Integer.parseInt(userHeader) : -1;
        int id = Integer.parseInt(ctx.pathParam("id"));
        Answer existing = answerDAO.findById(id);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        if (!isAdmin && existing.getUserId() != userId) { ctx.status(403).json("forbidden"); return; }
        Answer input = ctx.bodyAsClass(Answer.class);
        existing.setContent(input.getContent() != null ? input.getContent() : existing.getContent());
        boolean ok = answerDAO.updateAnswer(existing);
        if (ok) ctx.json(existing); else ctx.status(500).json("update_failed");
    };

    public static Handler deleteAnswer = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        boolean isAdmin = "true".equalsIgnoreCase(ctx.header("X-Admin"));
        if (userHeader == null && !isAdmin) { ctx.status(401).json("user_required"); return; }
        int userId = userHeader != null ? Integer.parseInt(userHeader) : -1;
        int id = Integer.parseInt(ctx.pathParam("id"));
        Answer existing = answerDAO.findById(id);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        if (!isAdmin && existing.getUserId() != userId) { ctx.status(403).json("forbidden"); return; }
        boolean ok = answerDAO.deleteAnswer(id);
        if (ok) ctx.status(204); else ctx.status(500).json("delete_failed");
    };

    public static Handler acceptAnswer = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        boolean isAdmin = "true".equalsIgnoreCase(ctx.header("X-Admin"));
        if (userHeader == null && !isAdmin) { ctx.status(401).json("user_required"); return; }
        int userId = userHeader != null ? Integer.parseInt(userHeader) : -1;
        int id = Integer.parseInt(ctx.pathParam("id"));
        Answer answer = answerDAO.findById(id);
        if (answer == null) { ctx.status(404).json("not_found"); return; }
        Question q = questionDAO.findById(answer.getQuestionId());
        if (q == null) { ctx.status(404).json("question_not_found"); return; }
        if (!isAdmin && q.getUserId() != userId) { ctx.status(403).json("forbidden"); return; }
        boolean ok = answerDAO.acceptAnswer(id, answer.getQuestionId());
        if (ok) ctx.json("accepted"); else ctx.status(500).json("accept_failed");
    };
}
