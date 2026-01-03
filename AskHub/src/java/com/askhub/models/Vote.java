package com.askhub.models;
import java.sql.Timestamp;
public class Vote {
    private int id;
    private int userId;
    private String targetType;
    private int targetId;
    private String voteType;
    private Timestamp createdAt;
    public Vote() {
    }
    public Vote(int userId, String targetType, int targetId, String voteType) {
        this.userId = userId;
        this.targetType = targetType;
        this.targetId = targetId;
        this.voteType = voteType;
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
    public String getTargetType() {
        return targetType;
    }
    public void setTargetType(String targetType) {
        this.targetType = targetType;
    }
    public int getTargetId() {
        return targetId;
    }
    public void setTargetId(int targetId) {
        this.targetId = targetId;
    }
    public String getVoteType() {
        return voteType;
    }
    public void setVoteType(String voteType) {
        this.voteType = voteType;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    @Override
    public String toString() {
        return "Vote{" +
                "id=" + id +
                ", userId=" + userId +
                ", targetType='" + targetType + '\'' +
                ", targetId=" + targetId +
                ", voteType='" + voteType + '\'' +
                '}';
    }
}
