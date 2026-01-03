package com.askhub.dao;
import com.askhub.models.Vote;
import com.askhub.utils.DatabaseConfig;
import java.sql.*;
public class VoteDAO {
    public boolean vote(Vote vote) {
        Vote existingVote = findVote(vote.getUserId(), vote.getTargetType(), vote.getTargetId());
        if (existingVote != null) {
            if (existingVote.getVoteType().equals(vote.getVoteType())) {
                return removeVote(vote.getUserId(), vote.getTargetType(), vote.getTargetId());
            } else {
                return updateVote(vote);
            }
        } else {
            return createVote(vote);
        }
    }
    private boolean createVote(Vote vote) {
        String sql = "INSERT INTO votes (user_id, target_type, target_id, vote_type) VALUES (?, ?, ?, ?)";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, vote.getUserId());
            stmt.setString(2, vote.getTargetType());
            stmt.setInt(3, vote.getTargetId());
            stmt.setString(4, vote.getVoteType());
            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                updateTargetVoteCount(vote.getTargetType(), vote.getTargetId(),
                                    vote.getVoteType().equals("UPVOTE") ? 1 : -1);
                // notify owner
                try {
                    int ownerId = -1;
                    if (vote.getTargetType().equals("QUESTION")) {
                        ownerId = new com.askhub.dao.QuestionDAO().findById(vote.getTargetId()).getUserId();
                    } else if (vote.getTargetType().equals("ANSWER")) {
                        ownerId = new com.askhub.dao.AnswerDAO().findById(vote.getTargetId()).getUserId();
                    }
                    if (ownerId > 0 && ownerId != vote.getUserId()) {
                        com.askhub.dao.NotificationDAO nd = new com.askhub.dao.NotificationDAO();
                        com.askhub.models.Notification n = new com.askhub.models.Notification();
                        n.setUserId(ownerId);
                        n.setType("VOTE");
                        n.setContent("Someone voted on your post.");
                        n.setReferenceType(vote.getTargetType());
                        n.setReferenceId(vote.getTargetId());
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
    private boolean updateVote(Vote vote) {
        String sql = "UPDATE votes SET vote_type = ? WHERE user_id = ? AND target_type = ? AND target_id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, vote.getVoteType());
            stmt.setInt(2, vote.getUserId());
            stmt.setString(3, vote.getTargetType());
            stmt.setInt(4, vote.getTargetId());
            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                updateTargetVoteCount(vote.getTargetType(), vote.getTargetId(),
                                    vote.getVoteType().equals("UPVOTE") ? 2 : -2);
                // notify owner about vote change
                try {
                    int ownerId = -1;
                    if (vote.getTargetType().equals("QUESTION")) {
                        ownerId = new com.askhub.dao.QuestionDAO().findById(vote.getTargetId()).getUserId();
                    } else if (vote.getTargetType().equals("ANSWER")) {
                        ownerId = new com.askhub.dao.AnswerDAO().findById(vote.getTargetId()).getUserId();
                    }
                    if (ownerId > 0 && ownerId != vote.getUserId()) {
                        com.askhub.dao.NotificationDAO nd = new com.askhub.dao.NotificationDAO();
                        com.askhub.models.Notification n = new com.askhub.models.Notification();
                        n.setUserId(ownerId);
                        n.setType("VOTE");
                        n.setContent("Someone changed their vote on your post.");
                        n.setReferenceType(vote.getTargetType());
                        n.setReferenceId(vote.getTargetId());
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
    private boolean removeVote(int userId, String targetType, int targetId) {
        Vote vote = findVote(userId, targetType, targetId);
        if (vote == null) return false;
        String sql = "DELETE FROM votes WHERE user_id = ? AND target_type = ? AND target_id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, targetType);
            stmt.setInt(3, targetId);
            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected > 0) {
                updateTargetVoteCount(targetType, targetId,
                                    vote.getVoteType().equals("UPVOTE") ? -1 : 1);
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    public Vote findVote(int userId, String targetType, int targetId) {
        String sql = "SELECT * FROM votes WHERE user_id = ? AND target_type = ? AND target_id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, targetType);
            stmt.setInt(3, targetId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return extractVoteFromResultSet(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    private void updateTargetVoteCount(String targetType, int targetId, int change) {
        if (targetType.equals("QUESTION")) {
            new QuestionDAO().updateVoteCount(targetId, change);
        } else if (targetType.equals("ANSWER")) {
            new AnswerDAO().updateVoteCount(targetId, change);
        }
    }
    public int getVoteCount(String targetType, int targetId) {
        String sql = "SELECT " +
                     "SUM(CASE WHEN vote_type = 'UPVOTE' THEN 1 ELSE -1 END) as vote_count " +
                     "FROM votes WHERE target_type = ? AND target_id = ?";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, targetType);
            stmt.setInt(2, targetId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("vote_count");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    private Vote extractVoteFromResultSet(ResultSet rs) throws SQLException {
        Vote vote = new Vote();
        vote.setId(rs.getInt("id"));
        vote.setUserId(rs.getInt("user_id"));
        vote.setTargetType(rs.getString("target_type"));
        vote.setTargetId(rs.getInt("target_id"));
        vote.setVoteType(rs.getString("vote_type"));
        vote.setCreatedAt(rs.getTimestamp("created_at"));
        return vote;
    }
}
