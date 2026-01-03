package com.askhub.dao;
import com.askhub.models.Topic;
import com.askhub.utils.DatabaseConfig;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
public class TopicDAO {
    public List<Topic> getAllTopics() {
        List<Topic> topics = new ArrayList<>();
        String sql = "SELECT * FROM topics ORDER BY question_count DESC, name ASC";
        try (Connection conn = DatabaseConfig.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                topics.add(extractTopicFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return topics;
    }
    public Topic findById(int id) {
        String sql = "SELECT * FROM topics WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return extractTopicFromResultSet(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    public Topic findBySlug(String slug) {
        String sql = "SELECT * FROM topics WHERE slug = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, slug);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return extractTopicFromResultSet(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    public boolean createTopic(Topic topic) {
        String sql = "INSERT INTO topics (name, description, slug) VALUES (?, ?, ?)";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setString(1, topic.getName());
            stmt.setString(2, topic.getDescription());
            stmt.setString(3, topic.getSlug());
            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                ResultSet rs = stmt.getGeneratedKeys();
                if (rs.next()) {
                    topic.setId(rs.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public void incrementQuestionCount(int topicId) {
        String sql = "UPDATE topics SET question_count = question_count + 1 WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, topicId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    private Topic extractTopicFromResultSet(ResultSet rs) throws SQLException {
        Topic topic = new Topic();
        topic.setId(rs.getInt("id"));
        topic.setName(rs.getString("name"));
        topic.setDescription(rs.getString("description"));
        topic.setSlug(rs.getString("slug"));
        topic.setQuestionCount(rs.getInt("question_count"));
        topic.setCreatedAt(rs.getTimestamp("created_at"));
        return topic;
    }
}
