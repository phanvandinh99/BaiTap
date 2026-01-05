package com.askhub.api;

import io.javalin.Javalin;

public class ApiServer {
    private Javalin app;

    public void start(int port) {
        app = Javalin.create(config -> {
            config.defaultContentType = "application/json";
        }).start(port);

        // Enable CORS for Flutter web
        app.before(ctx -> {
            ctx.header("Access-Control-Allow-Origin", "*");
            ctx.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
            ctx.header("Access-Control-Allow-Headers", "Content-Type, X-User-Id, X-Admin");
            ctx.header("Access-Control-Max-Age", "3600");
        });

        // Handle OPTIONS preflight requests
        app.options("/*", ctx -> {
            ctx.status(200);
        });

        // Register routes
        UserApi.registerRoutes(app);
        TopicApi.registerRoutes(app);
        QuestionApi.registerRoutes(app);
        AnswerApi.registerRoutes(app);
        CommentApi.registerRoutes(app);
        VoteApi.registerRoutes(app);
        NotificationApi.registerRoutes(app);
    }

    public void stop() {
        if (app != null) app.stop();
    }

    public static void main(String[] args) {
        ApiServer server = new ApiServer();
        server.start(7001);
    }
}
