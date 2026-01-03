package com.askhub.dao;
import com.askhub.models.Question;
import com.askhub.models.User;
import com.askhub.utils.DatabaseConfig;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
public class QuestionDAO {
    public boolean createQuestion(Question question) {
        String sql = "INSERT INTO questions (user_id, topic_id, title, content, status) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, question.getUserId());
            stmt.setInt(2, question.getTopicId());
            stmt.setString(3, question.getTitle());
            stmt.setString(4, question.getContent());
            stmt.setString(5, question.getStatus());
            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                ResultSet rs = stmt.getGeneratedKeys();
                if (rs.next()) {
                    question.setId(rs.getInt(1));
                }
                new TopicDAO().incrementQuestionCount(question.getTopicId());
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public List<Question> getAllQuestions(int page, int pageSize) {
        List<Question> questions = new ArrayList<>();
        String sql = "SELECT q.*, u.username, t.name as topic_name " +
                     "FROM questions q " +
                     "JOIN users u ON q.user_id = u.id " +
                     "JOIN topics t ON q.topic_id = t.id " +
                     "ORDER BY q.created_at DESC " +
                     "LIMIT ? OFFSET ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, pageSize);
            stmt.setInt(2, (page - 1) * pageSize);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                questions.add(extractQuestionFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return questions;
    }
    public Question findById(int id) {
        String sql = "SELECT q.*, u.username, u.full_name, u.reputation, u.avatar_url, t.name as topic_name " +
                     "FROM questions q " +
                     "JOIN users u ON q.user_id = u.id " +
                     "JOIN topics t ON q.topic_id = t.id " +
                     "WHERE q.id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                Question question = extractQuestionFromResultSet(rs);
                User author = new User();
                author.setId(rs.getInt("user_id"));
                author.setUsername(rs.getString("username"));
                author.setFullName(rs.getString("full_name"));
                author.setReputation(rs.getInt("reputation"));
                author.setAvatarUrl(rs.getString("avatar_url"));
                question.setAuthor(author);
                return question;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    public List<Question> getQuestionsByTopic(int topicId, int page, int pageSize) {
        List<Question> questions = new ArrayList<>();
        String sql = "SELECT q.*, u.username, t.name as topic_name " +
                     "FROM questions q " +
                     "JOIN users u ON q.user_id = u.id " +
                     "JOIN topics t ON q.topic_id = t.id " +
                     "WHERE q.topic_id = ? " +
                     "ORDER BY q.created_at DESC " +
                     "LIMIT ? OFFSET ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, topicId);
            stmt.setInt(2, pageSize);
            stmt.setInt(3, (page - 1) * pageSize);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                questions.add(extractQuestionFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return questions;
    }
    public List<Question> getQuestionsByUser(int userId) {
        List<Question> questions = new ArrayList<>();
        String sql = "SELECT q.*, u.username, t.name as topic_name " +
                     "FROM questions q " +
                     "JOIN users u ON q.user_id = u.id " +
                     "JOIN topics t ON q.topic_id = t.id " +
                     "WHERE q.user_id = ? " +
                     "ORDER BY q.created_at DESC";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                questions.add(extractQuestionFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return questions;
    }
    public List<Question> searchQuestions(String keyword, int page, int pageSize) {
        List<Question> questions = new ArrayList<>();
        String sql = "SELECT q.*, u.username, t.name as topic_name " +
                     "FROM questions q " +
                     "JOIN users u ON q.user_id = u.id " +
                     "JOIN topics t ON q.topic_id = t.id " +
                     "WHERE MATCH(q.title, q.content) AGAINST(? IN NATURAL LANGUAGE MODE) " +
                     "ORDER BY q.created_at DESC " +
                     "LIMIT ? OFFSET ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, keyword);
            stmt.setInt(2, pageSize);
            stmt.setInt(3, (page - 1) * pageSize);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                questions.add(extractQuestionFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return questions;
    }
    public void incrementViewCount(int questionId) {
        String sql = "UPDATE questions SET view_count = view_count + 1 WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, questionId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void updateVoteCount(int questionId, int voteChange) {
        String sql = "UPDATE questions SET vote_count = vote_count + ? WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, voteChange);
            stmt.setInt(2, questionId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void incrementAnswerCount(int questionId) {
        String sql = "UPDATE questions SET answer_count = answer_count + 1 WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, questionId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public boolean updateStatus(int questionId, String status) {
        String sql = "UPDATE questions SET status = ? WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setInt(2, questionId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public int getTotalCount() {
        String sql = "SELECT COUNT(*) FROM questions";
        try (Connection conn = DatabaseConfig.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    public boolean updateQuestion(Question question) {
        String sql = "UPDATE questions SET title = ?, content = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, question.getTitle());
            stmt.setString(2, question.getContent());
            stmt.setInt(3, question.getId());
            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public boolean deleteQuestion(int questionId) {
        // Get topic id first
        Question q = findById(questionId);
        int topicId = (q != null) ? q.getTopicId() : -1;
        String sql = "DELETE FROM questions WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, questionId);
            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                if (topicId > 0) new TopicDAO().decrementQuestionCount(topicId);
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public int getTotalQuestionCount() {
        String sql = "SELECT COUNT(*) as total FROM questions";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    private Question extractQuestionFromResultSet(ResultSet rs) throws SQLException {
        Question question = new Question();
        question.setId(rs.getInt("id"));
        question.setUserId(rs.getInt("user_id"));
        question.setTopicId(rs.getInt("topic_id"));
        question.setTitle(rs.getString("title"));
        question.setContent(rs.getString("content"));
        question.setStatus(rs.getString("status"));
        question.setViewCount(rs.getInt("view_count"));
        question.setVoteCount(rs.getInt("vote_count"));
        question.setAnswerCount(rs.getInt("answer_count"));
        question.setCreatedAt(rs.getTimestamp("created_at"));
        question.setUpdatedAt(rs.getTimestamp("updated_at"));
        question.setUsername(rs.getString("username"));
        question.setTopicName(rs.getString("topic_name"));
        return question;
    }
}
