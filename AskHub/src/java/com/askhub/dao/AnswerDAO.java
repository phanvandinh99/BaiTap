package com.askhub.dao;
import com.askhub.models.Answer;
import com.askhub.models.Question;
import com.askhub.models.User;
import com.askhub.utils.DatabaseConfig;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
public class AnswerDAO {
    public boolean createAnswer(Answer answer) {
        String sql = "INSERT INTO answers (question_id, user_id, content) VALUES (?, ?, ?)";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, answer.getQuestionId());
            stmt.setInt(2, answer.getUserId());
            stmt.setString(3, answer.getContent());
            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                ResultSet rs = stmt.getGeneratedKeys();
                if (rs.next()) {
                    answer.setId(rs.getInt(1));
                }
                new QuestionDAO().incrementAnswerCount(answer.getQuestionId());
                // create notification for question owner
                try {
                    Question q = new QuestionDAO().findById(answer.getQuestionId());
                    if (q != null && q.getUserId() != answer.getUserId()) {
                        com.askhub.dao.NotificationDAO nd = new com.askhub.dao.NotificationDAO();
                        com.askhub.models.Notification n = new com.askhub.models.Notification();
                        n.setUserId(q.getUserId());
                        n.setType("NEW_ANSWER");
                        n.setContent("Your question has a new answer.");
                        n.setReferenceType("QUESTION");
                        n.setReferenceId(q.getId());
                        nd.createNotification(n);
                    }
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public List<Answer> getAnswersByQuestion(int questionId) {
        List<Answer> answers = new ArrayList<>();
        String sql = "SELECT a.*, u.username, u.full_name, u.reputation, u.avatar_url " +
                     "FROM answers a " +
                     "JOIN users u ON a.user_id = u.id " +
                     "WHERE a.question_id = ? " +
                     "ORDER BY a.is_accepted DESC, a.vote_count DESC, a.created_at ASC";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, questionId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Answer answer = extractAnswerFromResultSet(rs);
                User author = new User();
                author.setId(rs.getInt("user_id"));
                author.setUsername(rs.getString("username"));
                author.setFullName(rs.getString("full_name"));
                author.setReputation(rs.getInt("reputation"));
                author.setAvatarUrl(rs.getString("avatar_url"));
                answer.setAuthor(author);
                answers.add(answer);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return answers;
    }
    public Answer findById(int id) {
        String sql = "SELECT a.*, u.username " +
                     "FROM answers a " +
                     "JOIN users u ON a.user_id = u.id " +
                     "WHERE a.id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return extractAnswerFromResultSet(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    public List<Answer> getAnswersByUser(int userId) {
        List<Answer> answers = new ArrayList<>();
        String sql = "SELECT a.*, u.username " +
                     "FROM answers a " +
                     "JOIN users u ON a.user_id = u.id " +
                     "WHERE a.user_id = ? " +
                     "ORDER BY a.created_at DESC";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                answers.add(extractAnswerFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return answers;
    }
    public void updateVoteCount(int answerId, int voteChange) {
        String sql = "UPDATE answers SET vote_count = vote_count + ? WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, voteChange);
            stmt.setInt(2, answerId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public boolean acceptAnswer(int answerId, int questionId) {
        Connection conn = null;
        try {
            conn = DatabaseConfig.getConnection();
            conn.setAutoCommit(false);
            String unacceptSql = "UPDATE answers SET is_accepted = FALSE WHERE question_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(unacceptSql)) {
                stmt.setInt(1, questionId);
                stmt.executeUpdate();
            }
            String acceptSql = "UPDATE answers SET is_accepted = TRUE WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(acceptSql)) {
                stmt.setInt(1, answerId);
                stmt.executeUpdate();
            }
            String updateQuestionSql = "UPDATE questions SET status = 'ANSWERED' WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(updateQuestionSql)) {
                stmt.setInt(1, questionId);
                stmt.executeUpdate();
            }
            conn.commit();
            // notify answer author about acceptance
            try {
                Answer a = findById(answerId);
                if (a != null) {
                    int answerAuthor = a.getUserId();
                    com.askhub.dao.NotificationDAO nd = new com.askhub.dao.NotificationDAO();
                    com.askhub.models.Notification n = new com.askhub.models.Notification();
                    n.setUserId(answerAuthor);
                    n.setType("ACCEPTED_ANSWER");
                    n.setContent("Your answer was accepted.");
                    n.setReferenceType("ANSWER");
                    n.setReferenceId(answerId);
                    nd.createNotification(n);
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }
            return true;
        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
        return false;
    }
    public boolean updateAnswer(Answer answer) {
        String sql = "UPDATE answers SET content = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, answer.getContent());
            stmt.setInt(2, answer.getId());
            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public boolean deleteAnswer(int answerId) {
        String sql = "DELETE FROM answers WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, answerId);
            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    private Answer extractAnswerFromResultSet(ResultSet rs) throws SQLException {
        Answer answer = new Answer();
        answer.setId(rs.getInt("id"));
        answer.setQuestionId(rs.getInt("question_id"));
        answer.setUserId(rs.getInt("user_id"));
        answer.setContent(rs.getString("content"));
        answer.setVoteCount(rs.getInt("vote_count"));
        answer.setAccepted(rs.getBoolean("is_accepted"));
        answer.setCreatedAt(rs.getTimestamp("created_at"));
        answer.setUpdatedAt(rs.getTimestamp("updated_at"));
        answer.setUsername(rs.getString("username"));
        return answer;
    }
}
