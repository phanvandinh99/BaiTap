package com.askhub.models;
import java.sql.Timestamp;
public class Topic {
    private int id;
    private String name;
    private String description;
    private String slug;
    private int questionCount;
    private Timestamp createdAt;
    public Topic() {
    }
    public Topic(String name, String description, String slug) {
        this.name = name;
        this.description = description;
        this.slug = slug;
        this.questionCount = 0;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getDescription() {
        return description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    public String getSlug() {
        return slug;
    }
    public void setSlug(String slug) {
        this.slug = slug;
    }
    public int getQuestionCount() {
        return questionCount;
    }
    public void setQuestionCount(int questionCount) {
        this.questionCount = questionCount;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    @Override
    public String toString() {
        return "Topic{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", slug='" + slug + '\'' +
                ", questionCount=" + questionCount +
                '}';
    }
}
