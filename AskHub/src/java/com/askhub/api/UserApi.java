package com.askhub.api;

import com.askhub.dao.UserDAO;
import com.askhub.models.User;
import io.javalin.Javalin;
import io.javalin.http.Handler;

public class UserApi {
    private static final UserDAO userDAO = new UserDAO();

    public static void registerRoutes(Javalin app) {
        app.post("/api/register", registerHandler);
        app.post("/api/login", loginHandler);
        app.get("/api/users/{id}", getUserHandler);
        app.put("/api/users/{id}", updateUserHandler);
        app.get("/api/users", listUsersHandler);
        app.delete("/api/users/{id}", deactivateUserHandler);
    }

    public static Handler registerHandler = ctx -> {
        User input = ctx.bodyAsClass(User.class);
        if (input.getUsername() == null || input.getEmail() == null || input.getPassword() == null) {
            ctx.status(400).json("username, email, password are required");
            return;
        }
        if (userDAO.findByUsername(input.getUsername()) != null) {
            ctx.status(409).json("username_exists");
            return;
        }
        if (userDAO.findByEmail(input.getEmail()) != null) {
            ctx.status(409).json("email_exists");
            return;
        }
        User newUser = new User(input.getUsername(), input.getEmail(), input.getPassword(), input.getFullName());
        boolean ok = userDAO.createUser(newUser);
        if (ok) {
            newUser.setPassword(null);
            ctx.status(201).json(newUser);
        } else {
            ctx.status(500).json("create_failed");
        }
    };

    public static Handler loginHandler = ctx -> {
        LoginRequest req = ctx.bodyAsClass(LoginRequest.class);
        if (req.username == null || req.password == null) {
            ctx.status(400).json("username and password required");
            return;
        }
        User user = userDAO.authenticate(req.username, req.password);
        if (user != null) {
            user.setPassword(null);
            ctx.json(user);
        } else {
            ctx.status(401).json("invalid_credentials");
        }
    };

    public static Handler getUserHandler = ctx -> {
        int id = Integer.parseInt(ctx.pathParam("id"));
        User user = userDAO.findById(id);
        if (user != null) {
            user.setPassword(null);
            ctx.json(user);
        } else {
            ctx.status(404).json("not_found");
        }
    };

    public static Handler updateUserHandler = ctx -> {
        int id = Integer.parseInt(ctx.pathParam("id"));
        User existing = userDAO.findById(id);
        if (existing == null) {
            ctx.status(404).json("not_found");
            return;
        }
        User input = ctx.bodyAsClass(User.class);
        // Only allow updating fullName, bio, avatarUrl
        existing.setFullName(input.getFullName());
        existing.setBio(input.getBio());
        existing.setAvatarUrl(input.getAvatarUrl());
        boolean ok = userDAO.updateUser(existing);
        if (ok) {
            existing.setPassword(null);
            ctx.json(existing);
        } else {
            ctx.status(500).json("update_failed");
        }
    };

    public static Handler listUsersHandler = ctx -> {
        ctx.json(userDAO.getAllUsers().stream().peek(u -> u.setPassword(null)).toArray());
    };

    public static Handler deactivateUserHandler = ctx -> {
        int id = Integer.parseInt(ctx.pathParam("id"));
        boolean ok = userDAO.deactivateUser(id);
        if (ok) ctx.status(204);
        else ctx.status(500).json("deactivate_failed");
    };

    // Simple DTO for login
    public static class LoginRequest {
        public String username;
        public String password;
    }
}
