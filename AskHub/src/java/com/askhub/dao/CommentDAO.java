package com.askhub.dao;
import com.askhub.models.Comment;
import com.askhub.utils.DatabaseConfig;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
public class CommentDAO {
    public boolean createComment(Comment comment) {
        String sql = "INSERT INTO comments (user_id, target_type, target_id, content) VALUES (?, ?, ?, ?)";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, comment.getUserId());
            stmt.setString(2, comment.getTargetType());
            stmt.setInt(3, comment.getTargetId());
            stmt.setString(4, comment.getContent());
            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                ResultSet rs = stmt.getGeneratedKeys();
                if (rs.next()) {
                    comment.setId(rs.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public List<Comment> getCommentsByTarget(String targetType, int targetId) {
        List<Comment> comments = new ArrayList<>();
        String sql = "SELECT c.*, u.username " +
                     "FROM comments c " +
                     "JOIN users u ON c.user_id = u.id " +
                     "WHERE c.target_type = ? AND c.target_id = ? " +
                     "ORDER BY c.created_at ASC";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, targetType);
            stmt.setInt(2, targetId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                comments.add(extractCommentFromResultSet(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return comments;
    }
    public Comment findById(int commentId) {
        String sql = "SELECT c.*, u.username " +
                     "FROM comments c " +
                     "JOIN users u ON c.user_id = u.id " +
                     "WHERE c.id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, commentId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return extractCommentFromResultSet(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    public boolean updateComment(Comment comment) {
        String sql = "UPDATE comments SET content = ? WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, comment.getContent());
            stmt.setInt(2, comment.getId());
            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public boolean deleteComment(int commentId) {
        String sql = "DELETE FROM comments WHERE id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, commentId);
            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public int getCommentCount(String targetType, int targetId) {
        String sql = "SELECT COUNT(*) FROM comments WHERE target_type = ? AND target_id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, targetType);
            stmt.setInt(2, targetId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    private Comment extractCommentFromResultSet(ResultSet rs) throws SQLException {
        Comment comment = new Comment();
        comment.setId(rs.getInt("id"));
        comment.setUserId(rs.getInt("user_id"));
        comment.setTargetType(rs.getString("target_type"));
        comment.setTargetId(rs.getInt("target_id"));
        comment.setContent(rs.getString("content"));
        comment.setCreatedAt(rs.getTimestamp("created_at"));
        comment.setUsername(rs.getString("username"));
        return comment;
    }
}
