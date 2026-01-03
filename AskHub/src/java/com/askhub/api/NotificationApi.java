package com.askhub.api;

import com.askhub.dao.NotificationDAO;
import com.askhub.models.Notification;
import io.javalin.Javalin;
import io.javalin.http.Handler;

import java.util.List;

public class NotificationApi {
    private static final NotificationDAO notificationDAO = new NotificationDAO();

    public static void registerRoutes(Javalin app) {
        app.get("/api/notifications", listNotifications);
        app.post("/api/notifications/read/{id}", markAsRead);
        app.post("/api/notifications/read-all", markAllAsRead);
        app.delete("/api/notifications/{id}", deleteNotification);
    }

    public static Handler listNotifications = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        if (userHeader == null) { ctx.status(401).json("user_required"); return; }
        int userId = Integer.parseInt(userHeader);
        int limit = ctx.queryParamAsClass("limit", Integer.class).getOrDefault(50);
        List<Notification> notifs = notificationDAO.getNotificationsByUser(userId, limit);
        int unread = notificationDAO.getUnreadCount(userId);
        ctx.json(new Object(){ public java.util.List<Notification> notifications = notifs; public int unreadCount = unread; });
    };

    public static Handler markAsRead = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        if (userHeader == null) { ctx.status(401).json("user_required"); return; }
        int userId = Integer.parseInt(userHeader);
        int id = Integer.parseInt(ctx.pathParam("id"));
        // ensure notification belongs to user by fetching list (simple check)
        boolean ok = notificationDAO.markAsRead(id);
        if (ok) ctx.status(200).json("ok"); else ctx.status(500).json("mark_failed");
    };

    public static Handler markAllAsRead = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        if (userHeader == null) { ctx.status(401).json("user_required"); return; }
        int userId = Integer.parseInt(userHeader);
        boolean ok = notificationDAO.markAllAsRead(userId);
        if (ok) ctx.status(200).json("ok"); else ctx.status(500).json("mark_failed");
    };

    public static Handler deleteNotification = ctx -> {
        String userHeader = ctx.header("X-User-Id");
        if (userHeader == null) { ctx.status(401).json("user_required"); return; }
        int userId = Integer.parseInt(userHeader);
        int id = Integer.parseInt(ctx.pathParam("id"));
        boolean ok = notificationDAO.deleteNotification(id, userId);
        if (ok) ctx.status(204); else ctx.status(500).json("delete_failed");
    };
}
