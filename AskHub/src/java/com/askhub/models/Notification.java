package com.askhub.models;
import java.sql.Timestamp;
public class Notification {
    private int id;
    private int userId;
    private String type;
    private String content;
    private String referenceType;
    private Integer referenceId;
    private boolean isRead;
    private Timestamp createdAt;
    public Notification() {
    }
    public Notification(int userId, String type, String content) {
        this.userId = userId;
        this.type = type;
        this.content = content;
        this.isRead = false;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getUserId() {
        return userId;
    }
    public void setUserId(int userId) {
        this.userId = userId;
    }
    public String getType() {
        return type;
    }
    public void setType(String type) {
        this.type = type;
    }
    public String getContent() {
        return content;
    }
    public void setContent(String content) {
        this.content = content;
    }
    public String getReferenceType() {
        return referenceType;
    }
    public void setReferenceType(String referenceType) {
        this.referenceType = referenceType;
    }
    public Integer getReferenceId() {
        return referenceId;
    }
    public void setReferenceId(Integer referenceId) {
        this.referenceId = referenceId;
    }
    public boolean isRead() {
        return isRead;
    }
    public void setRead(boolean read) {
        isRead = read;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    @Override
    public String toString() {
        return "Notification{" +
                "id=" + id +
                ", type='" + type + '\'' +
                ", isRead=" + isRead +
                ", createdAt=" + createdAt +
                '}';
    }
}
