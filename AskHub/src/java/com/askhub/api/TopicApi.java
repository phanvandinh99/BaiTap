package com.askhub.api;

import com.askhub.dao.QuestionDAO;
import com.askhub.dao.TopicDAO;
import com.askhub.models.Question;
import com.askhub.models.Topic;
import io.javalin.Javalin;
import io.javalin.http.Handler;

import java.util.List;

public class TopicApi {
    private static final TopicDAO topicDAO = new TopicDAO();
    private static final QuestionDAO questionDAO = new QuestionDAO();

    public static void registerRoutes(Javalin app) {
        app.get("/api/topics", listTopics);
        app.get("/api/topics/{id}", getTopic);
        app.post("/api/topics", createTopic);
        app.put("/api/topics/{id}", updateTopic);
        app.delete("/api/topics/{id}", deleteTopic);
    }

    public static Handler listTopics = ctx -> {
        ctx.json(topicDAO.getAllTopics());
    };

    public static Handler getTopic = ctx -> {
        int id = Integer.parseInt(ctx.pathParam("id"));
        Topic topic = topicDAO.findById(id);
        if (topic == null) {
            ctx.status(404).json("not_found");
            return;
        }
        int page = ctx.queryParamAsClass("page", Integer.class).getOrDefault(1);
        int pageSize = ctx.queryParamAsClass("pageSize", Integer.class).getOrDefault(20);
        List<Question> questions = questionDAO.getQuestionsByTopic(id, page, pageSize);
        ctx.attribute("topic", topic);
        ctx.json(new Object(){
            public Topic t = topic;
            public List<Question> q = questions;
        });
    };

    private static boolean isAdmin(io.javalin.http.Context ctx) {
        String adminHeader = ctx.header("X-Admin");
        return adminHeader != null && ("true".equalsIgnoreCase(adminHeader) || "1".equals(adminHeader));
    }

    public static Handler createTopic = ctx -> {
        if (!isAdmin(ctx)) { ctx.status(403).json("admin_required"); return; }
        Topic input = ctx.bodyAsClass(Topic.class);
        if (input.getName() == null || input.getSlug() == null) {
            ctx.status(400).json("name_and_slug_required");
            return;
        }
        Topic existing = topicDAO.findBySlug(input.getSlug());
        if (existing != null) { ctx.status(409).json("slug_exists"); return; }
        boolean ok = topicDAO.createTopic(input);
        if (ok) ctx.status(201).json(input);
        else ctx.status(500).json("create_failed");
    };

    public static Handler updateTopic = ctx -> {
        if (!isAdmin(ctx)) { ctx.status(403).json("admin_required"); return; }
        int id = Integer.parseInt(ctx.pathParam("id"));
        Topic existing = topicDAO.findById(id);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        Topic input = ctx.bodyAsClass(Topic.class);
        existing.setName(input.getName() != null ? input.getName() : existing.getName());
        existing.setDescription(input.getDescription() != null ? input.getDescription() : existing.getDescription());
        existing.setSlug(input.getSlug() != null ? input.getSlug() : existing.getSlug());
        boolean ok = topicDAO.updateTopic(existing);
        if (ok) ctx.json(existing);
        else ctx.status(500).json("update_failed");
    };

    public static Handler deleteTopic = ctx -> {
        if (!isAdmin(ctx)) { ctx.status(403).json("admin_required"); return; }
        int id = Integer.parseInt(ctx.pathParam("id"));
        Topic existing = topicDAO.findById(id);
        if (existing == null) { ctx.status(404).json("not_found"); return; }
        if (existing.getQuestionCount() > 0) { ctx.status(400).json("topic_has_questions"); return; }
        boolean ok = topicDAO.deleteTopic(id);
        if (ok) ctx.status(204);
        else ctx.status(500).json("delete_failed");
    };
}
