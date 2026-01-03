package com.askhub.utils;
import com.askhub.models.User;
/**
 * Manages user session for the desktop application
 */
public class SessionManager {
    private static SessionManager instance;
    private User currentUser;
    private SessionManager() {
    }
    public static SessionManager getInstance() {
        if (instance == null) {
            instance = new SessionManager();
        }
        return instance;
    }
    public void login(User user) {
        this.currentUser = user;
    }
    public void logout() {
        this.currentUser = null;
    }
    public User getCurrentUser() {
        return currentUser;
    }
    public boolean isLoggedIn() {
        return currentUser != null;
    }
    public int getCurrentUserId() {
        return currentUser != null ? currentUser.getId() : -1;
    }
    public String getCurrentUsername() {
        return currentUser != null ? currentUser.getUsername() : null;
    }
    public boolean isAdmin() {
        return currentUser != null && currentUser.isAdmin();
    }
}
