package com.askhub.api;

import io.javalin.Javalin;

public class ApiServer {
    private Javalin app;

    public void start(int port) {
        app = Javalin.create(config -> {
            config.defaultContentType = "application/json";
        }).start(port);

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
        server.start(7000);
    }
}
