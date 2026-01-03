package com.askhub.ui;
import com.askhub.dao.AnswerDAO;
import com.askhub.dao.QuestionDAO;
import com.askhub.dao.VoteDAO;
import com.askhub.dao.CommentDAO;
import com.askhub.models.Answer;
import com.askhub.models.Question;
import com.askhub.models.Vote;
import com.askhub.models.Comment;
import com.askhub.utils.SessionManager;
import javax.swing.*;
import java.awt.*;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.text.SimpleDateFormat;
import java.util.List;
public class QuestionDetailFrame extends JFrame {
    private Question question;
    private List<Answer> answers;
    private QuestionDAO questionDAO;
    private AnswerDAO answerDAO;
    private VoteDAO voteDAO;
    private CommentDAO commentDAO;
    private JPanel answersPanel;
    private JTextArea answerTextArea;
    private JButton postAnswerButton;
    private JLabel voteCountLabel;
    private JLabel answerCountLabel;
    private Timer autoRefreshTimer;
    private static final int REFRESH_INTERVAL = 15000;
    private int lastAnswerCount = 0;
    private int lastCommentCount = 0;
    public QuestionDetailFrame(int questionId) {
        questionDAO = new QuestionDAO();
        answerDAO = new AnswerDAO();
        voteDAO = new VoteDAO();
        commentDAO = new CommentDAO();
        question = questionDAO.findById(questionId);
        if (question == null) {
            JOptionPane.showMessageDialog(null, "Không tìm thấy câu hỏi", "Lỗi", JOptionPane.ERROR_MESSAGE);
            return;
        }
        questionDAO.incrementViewCount(questionId);
        answers = answerDAO.getAnswersByQuestion(questionId);
        lastAnswerCount = answers.size();
        initComponents();
        startAutoRefresh();
        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                stopAutoRefresh();
            }
        });
    }
    private void initComponents() {
        setTitle("AskHub - " + question.getTitle());
        setSize(900, 700);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        JPanel mainPanel = new JPanel(new BorderLayout());
        JPanel contentPanel = new JPanel();
        contentPanel.setLayout(new BoxLayout(contentPanel, BoxLayout.Y_AXIS));
        contentPanel.setBackground(Color.WHITE);
        contentPanel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));
        JPanel questionPanel = createQuestionPanel();
        contentPanel.add(questionPanel);
        JPanel answersHeaderPanel = new JPanel(new BorderLayout());
        answersHeaderPanel.setBackground(Color.WHITE);
        answersHeaderPanel.setBorder(BorderFactory.createEmptyBorder(20, 0, 10, 0));
        answerCountLabel = new JLabel(answers.size() + " Câu trả lời");
        answerCountLabel.setFont(new Font("Arial", Font.BOLD, 18));
        answersHeaderPanel.add(answerCountLabel, BorderLayout.WEST);
        contentPanel.add(answersHeaderPanel);
        answersPanel = new JPanel();
        answersPanel.setLayout(new BoxLayout(answersPanel, BoxLayout.Y_AXIS));
        answersPanel.setBackground(Color.WHITE);
        loadAnswers();
        contentPanel.add(answersPanel);
        JPanel answerFormPanel = createAnswerFormPanel();
        contentPanel.add(answerFormPanel);
        JScrollPane scrollPane = new JScrollPane(contentPanel);
        scrollPane.getVerticalScrollBar().setUnitIncrement(16);
        mainPanel.add(scrollPane, BorderLayout.CENTER);
        add(mainPanel);
    }
    private JPanel createQuestionPanel() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(200, 200, 200)),
                BorderFactory.createEmptyBorder(15, 15, 15, 15)
        ));
        JPanel votePanel = new JPanel();
        votePanel.setLayout(new BoxLayout(votePanel, BoxLayout.Y_AXIS));
        votePanel.setBackground(Color.WHITE);
        votePanel.setPreferredSize(new Dimension(60, 100));
        JButton upvoteBtn = new JButton("▲");
        upvoteBtn.setFont(new Font("Arial", Font.BOLD, 20));
        upvoteBtn.setFocusPainted(false);
        upvoteBtn.addActionListener(e -> handleVote("QUESTION", question.getId(), "UPVOTE"));
        voteCountLabel = new JLabel(String.valueOf(question.getVoteCount()));
        voteCountLabel.setFont(new Font("Arial", Font.BOLD, 24));
        voteCountLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
        JButton downvoteBtn = new JButton("▼");
        downvoteBtn.setFont(new Font("Arial", Font.BOLD, 20));
        downvoteBtn.setFocusPainted(false);
        downvoteBtn.addActionListener(e -> handleVote("QUESTION", question.getId(), "DOWNVOTE"));
        votePanel.add(upvoteBtn);
        votePanel.add(Box.createVerticalStrut(10));
        votePanel.add(voteCountLabel);
        votePanel.add(Box.createVerticalStrut(10));
        votePanel.add(downvoteBtn);
        JPanel contentPanel = new JPanel(new BorderLayout());
        contentPanel.setBackground(Color.WHITE);
        JLabel titleLabel = new JLabel("<html><h2>" + question.getTitle() + "</h2></html>");
        titleLabel.setFont(new Font("Arial", Font.BOLD, 20));
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        JPanel metaPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 5));
        metaPanel.setBackground(Color.WHITE);
        metaPanel.add(new JLabel("Chủ đề: " + question.getTopicName()));
        metaPanel.add(new JLabel("│"));
        metaPanel.add(new JLabel("Hỏi bởi: " + question.getAuthor().getUsername()));
        metaPanel.add(new JLabel("│"));
        metaPanel.add(new JLabel(sdf.format(question.getCreatedAt())));
        metaPanel.add(new JLabel("│"));
        metaPanel.add(new JLabel(question.getViewCount() + " lượt xem"));
        if (SessionManager.getInstance().getCurrentUserId() == question.getUserId()) {
            metaPanel.add(new JLabel("│"));
            JButton editQuestionBtn = new JButton("Sửa");
            editQuestionBtn.setFont(new Font("Arial", Font.PLAIN, 12));
            editQuestionBtn.setFocusPainted(false);
            editQuestionBtn.addActionListener(e -> handleEditQuestion());
            metaPanel.add(editQuestionBtn);
            JButton deleteQuestionBtn = new JButton("Xóa");
            deleteQuestionBtn.setFont(new Font("Arial", Font.PLAIN, 12));
            deleteQuestionBtn.setForeground(Color.RED);
            deleteQuestionBtn.setFocusPainted(false);
            deleteQuestionBtn.addActionListener(e -> handleDeleteQuestion());
            metaPanel.add(deleteQuestionBtn);
        }
        JTextArea contentArea = new JTextArea(question.getContent());
        contentArea.setFont(new Font("Arial", Font.PLAIN, 14));
        contentArea.setLineWrap(true);
        contentArea.setWrapStyleWord(true);
        contentArea.setEditable(false);
        contentArea.setBackground(Color.WHITE);
        contentArea.setBorder(BorderFactory.createEmptyBorder(10, 0, 10, 0));
        contentPanel.add(titleLabel, BorderLayout.NORTH);
        contentPanel.add(metaPanel, BorderLayout.CENTER);
        contentPanel.add(contentArea, BorderLayout.SOUTH);
        panel.add(votePanel, BorderLayout.WEST);
        panel.add(contentPanel, BorderLayout.CENTER);
        JPanel questionCommentsPanel = createCommentsPanel("QUESTION", question.getId());
        panel.add(questionCommentsPanel, BorderLayout.SOUTH);
        return panel;
    }
    private void loadAnswers() {
        answersPanel.removeAll();
        for (Answer answer : answers) {
            JPanel answerPanel = createAnswerPanel(answer);
            answersPanel.add(answerPanel);
            answersPanel.add(Box.createVerticalStrut(10));
        }
        answersPanel.revalidate();
        answersPanel.repaint();
    }
    private JPanel createAnswerPanel(Answer answer) {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 220, 220)),
                BorderFactory.createEmptyBorder(15, 15, 15, 15)
        ));
        if (answer.isAccepted()) {
            panel.setBackground(new Color(240, 255, 240));
        }
        JPanel votePanel = new JPanel();
        votePanel.setLayout(new BoxLayout(votePanel, BoxLayout.Y_AXIS));
        votePanel.setBackground(panel.getBackground());
        votePanel.setPreferredSize(new Dimension(60, 80));
        JButton upvoteBtn = new JButton("▲");
        upvoteBtn.setFont(new Font("Arial", Font.PLAIN, 16));
        upvoteBtn.setFocusPainted(false);
        upvoteBtn.addActionListener(e -> handleVote("ANSWER", answer.getId(), "UPVOTE"));
        JLabel answerVoteLabel = new JLabel(String.valueOf(answer.getVoteCount()));
        answerVoteLabel.setFont(new Font("Arial", Font.BOLD, 20));
        answerVoteLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
        JButton downvoteBtn = new JButton("▼");
        downvoteBtn.setFont(new Font("Arial", Font.PLAIN, 16));
        downvoteBtn.setFocusPainted(false);
        downvoteBtn.addActionListener(e -> handleVote("ANSWER", answer.getId(), "DOWNVOTE"));
        votePanel.add(upvoteBtn);
        votePanel.add(Box.createVerticalStrut(5));
        votePanel.add(answerVoteLabel);
        votePanel.add(Box.createVerticalStrut(5));
        votePanel.add(downvoteBtn);
        if (answer.isAccepted()) {
            JLabel acceptedLabel = new JLabel("✓");
            acceptedLabel.setFont(new Font("Arial", Font.BOLD, 24));
            acceptedLabel.setForeground(new Color(0, 150, 0));
            acceptedLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
            votePanel.add(Box.createVerticalStrut(5));
            votePanel.add(acceptedLabel);
        } else if (SessionManager.getInstance().getCurrentUserId() == question.getUserId()) {
            JButton acceptBtn = new JButton("Chấp nhận");
            acceptBtn.setFont(new Font("Arial", Font.PLAIN, 10));
            acceptBtn.setFocusPainted(false);
            acceptBtn.addActionListener(e -> handleAcceptAnswer(answer.getId()));
            votePanel.add(Box.createVerticalStrut(5));
            votePanel.add(acceptBtn);
        }
        JTextArea contentArea = new JTextArea(answer.getContent());
        contentArea.setFont(new Font("Arial", Font.PLAIN, 14));
        contentArea.setLineWrap(true);
        contentArea.setWrapStyleWord(true);
        contentArea.setEditable(false);
        contentArea.setBackground(panel.getBackground());
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        JPanel authorPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        authorPanel.setBackground(panel.getBackground());
        authorPanel.add(new JLabel("Trả lời bởi: " + answer.getUsername()));
        authorPanel.add(new JLabel("│"));
        authorPanel.add(new JLabel(sdf.format(answer.getCreatedAt())));
        if (SessionManager.getInstance().getCurrentUserId() == answer.getUserId()) {
            authorPanel.add(new JLabel("│"));
            JButton editBtn = new JButton("Sửa");
            editBtn.setFont(new Font("Arial", Font.PLAIN, 11));
            editBtn.setFocusPainted(false);
            editBtn.addActionListener(e -> handleEditAnswer(answer));
            authorPanel.add(editBtn);
            JButton deleteBtn = new JButton("Xóa");
            deleteBtn.setFont(new Font("Arial", Font.PLAIN, 11));
            deleteBtn.setForeground(Color.RED);
            deleteBtn.setFocusPainted(false);
            deleteBtn.addActionListener(e -> handleDeleteAnswer(answer.getId()));
            authorPanel.add(deleteBtn);
        }
        JPanel contentPanel = new JPanel(new BorderLayout());
        contentPanel.setBackground(panel.getBackground());
        contentPanel.add(contentArea, BorderLayout.CENTER);
        contentPanel.add(authorPanel, BorderLayout.SOUTH);
        panel.add(votePanel, BorderLayout.WEST);
        panel.add(contentPanel, BorderLayout.CENTER);
        JPanel answerCommentsPanel = createCommentsPanel("ANSWER", answer.getId());
        panel.add(answerCommentsPanel, BorderLayout.SOUTH);
        return panel;
    }
    private JPanel createCommentsPanel(String targetType, int targetId) {
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        panel.setBackground(new Color(250, 250, 250));
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        List<Comment> comments = commentDAO.getCommentsByTarget(targetType, targetId);
        JLabel commentsLabel = new JLabel(comments.size() + " Bình luận");
        commentsLabel.setFont(new Font("Arial", Font.BOLD, 12));
        commentsLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
        panel.add(commentsLabel);
        panel.add(Box.createVerticalStrut(5));
        for (Comment comment : comments) {
            JPanel commentPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 2));
            commentPanel.setBackground(new Color(250, 250, 250));
            commentPanel.setAlignmentX(Component.LEFT_ALIGNMENT);
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM HH:mm");
            JLabel commentText = new JLabel("<html><b>" + comment.getUsername() + "</b> (" +
                                           sdf.format(comment.getCreatedAt()) + "): " + comment.getContent() + "</html>");
            commentText.setFont(new Font("Arial", Font.PLAIN, 11));
            commentPanel.add(commentText);
            if (SessionManager.getInstance().getCurrentUserId() == comment.getUserId()) {
                JButton deleteBtn = new JButton("×");
                deleteBtn.setFont(new Font("Arial", Font.BOLD, 14));
                deleteBtn.setForeground(Color.RED);
                deleteBtn.setFocusPainted(false);
                deleteBtn.setBorderPainted(false);
                deleteBtn.setContentAreaFilled(false);
                deleteBtn.setCursor(new Cursor(Cursor.HAND_CURSOR));
                deleteBtn.addActionListener(e -> handleDeleteComment(comment.getId(), targetType, targetId));
                commentPanel.add(deleteBtn);
            }
            panel.add(commentPanel);
        }
        JPanel addCommentPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 5));
        addCommentPanel.setBackground(new Color(250, 250, 250));
        addCommentPanel.setAlignmentX(Component.LEFT_ALIGNMENT);
        JTextField commentField = new JTextField(40);
        commentField.setFont(new Font("Arial", Font.PLAIN, 11));
        addCommentPanel.add(commentField);
        JButton addCommentBtn = new JButton("Thêm bình luận");
        addCommentBtn.setFont(new Font("Arial", Font.PLAIN, 11));
        addCommentBtn.setFocusPainted(false);
        addCommentBtn.setCursor(new Cursor(Cursor.HAND_CURSOR));
        addCommentBtn.addActionListener(e -> {
            String content = commentField.getText().trim();
            if (!content.isEmpty()) {
                handleAddComment(targetType, targetId, content);
                commentField.setText("");
            } else {
                JOptionPane.showMessageDialog(this, "Vui lòng nhập nội dung bình luận", "Lỗi", JOptionPane.ERROR_MESSAGE);
            }
        });
        addCommentPanel.add(addCommentBtn);
        panel.add(addCommentPanel);
        return panel;
    }
    private void handleAddComment(String targetType, int targetId, String content) {
        Comment comment = new Comment(SessionManager.getInstance().getCurrentUserId(), targetType, targetId, content);
        boolean success = commentDAO.createComment(comment);
        if (success) {
            dispose();
            new QuestionDetailFrame(question.getId()).setVisible(true);
        } else {
            JOptionPane.showMessageDialog(this, "Thêm bình luận thất bại", "Lỗi", JOptionPane.ERROR_MESSAGE);
        }
    }
    private void handleDeleteComment(int commentId, String targetType, int targetId) {
        int confirm = JOptionPane.showConfirmDialog(this,
                "Bạn có chắc chắn muốn xóa bình luận này?",
                "Xác nhận xóa",
                JOptionPane.YES_NO_OPTION);
        if (confirm == JOptionPane.YES_OPTION) {
            boolean success = commentDAO.deleteComment(commentId);
            if (success) {
                dispose();
                new QuestionDetailFrame(question.getId()).setVisible(true);
            } else {
                JOptionPane.showMessageDialog(this, "Xóa thất bại", "Lỗi", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    private JPanel createAnswerFormPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createEmptyBorder(20, 0, 0, 0),
                BorderFactory.createLineBorder(new Color(200, 200, 200))
        ));
        JPanel headerPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        headerPanel.setBackground(new Color(240, 240, 240));
        JLabel headerLabel = new JLabel("Câu trả lời của bạn");
        headerLabel.setFont(new Font("Arial", Font.BOLD, 16));
        headerPanel.add(headerLabel);
        answerTextArea = new JTextArea(5, 50);
        answerTextArea.setFont(new Font("Arial", Font.PLAIN, 14));
        answerTextArea.setLineWrap(true);
        answerTextArea.setWrapStyleWord(true);
        JScrollPane scrollPane = new JScrollPane(answerTextArea);
        scrollPane.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.setBackground(Color.WHITE);
        postAnswerButton = new JButton("Đăng câu trả lời");
        postAnswerButton.setFont(new Font("Arial", Font.BOLD, 14));
        postAnswerButton.setBackground(new Color(0, 102, 204));
        postAnswerButton.setForeground(Color.WHITE);
        postAnswerButton.setFocusPainted(false);
        postAnswerButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        postAnswerButton.addActionListener(e -> handlePostAnswer());
        buttonPanel.add(postAnswerButton);
        panel.add(headerPanel, BorderLayout.NORTH);
        panel.add(scrollPane, BorderLayout.CENTER);
        panel.add(buttonPanel, BorderLayout.SOUTH);
        return panel;
    }
    private void handleVote(String targetType, int targetId, String voteType) {
        Vote vote = new Vote(SessionManager.getInstance().getCurrentUserId(), targetType, targetId, voteType);
        boolean success = voteDAO.vote(vote);
        if (success) {
            int newCount = voteDAO.getVoteCount(targetType, targetId);
            if (targetType.equals("QUESTION")) {
                voteCountLabel.setText(String.valueOf(newCount));
            } else {
                answers = answerDAO.getAnswersByQuestion(question.getId());
                loadAnswers();
            }
        }
    }
    private void handleAcceptAnswer(int answerId) {
        int confirm = JOptionPane.showConfirmDialog(this,
                "Chấp nhận câu trả lời này là giải pháp?",
                "Xác nhận",
                JOptionPane.YES_NO_OPTION);
        if (confirm == JOptionPane.YES_OPTION) {
            boolean success = answerDAO.acceptAnswer(answerId, question.getId());
            if (success) {
                JOptionPane.showMessageDialog(this, "Đã chấp nhận câu trả lời!", "Thành công", JOptionPane.INFORMATION_MESSAGE);
                answers = answerDAO.getAnswersByQuestion(question.getId());
                loadAnswers();
            }
        }
    }
    private void handlePostAnswer() {
        String content = answerTextArea.getText().trim();
        if (content.isEmpty()) {
            JOptionPane.showMessageDialog(this,
                    "Vui lòng nhập câu trả lời của bạn",
                    "Lỗi",
                    JOptionPane.ERROR_MESSAGE);
            return;
        }
        Answer answer = new Answer(question.getId(), SessionManager.getInstance().getCurrentUserId(), content);
        boolean success = answerDAO.createAnswer(answer);
        if (success) {
            JOptionPane.showMessageDialog(this,
                    "Đăng câu trả lời thành công!",
                    "Thành công",
                    JOptionPane.INFORMATION_MESSAGE);
            answerTextArea.setText("");
            answers = answerDAO.getAnswersByQuestion(question.getId());
            loadAnswers();
        } else {
            JOptionPane.showMessageDialog(this,
                    "Đăng câu trả lời thất bại",
                    "Lỗi",
                    JOptionPane.ERROR_MESSAGE);
        }
    }
    private void handleEditQuestion() {
        JTextField titleField = new JTextField(question.getTitle());
        JTextArea contentArea = new JTextArea(question.getContent(), 10, 40);
        contentArea.setLineWrap(true);
        contentArea.setWrapStyleWord(true);
        JScrollPane scrollPane = new JScrollPane(contentArea);
        Object[] message = {
            "Tiêu đề:", titleField,
            "Nội dung:", scrollPane
        };
        int option = JOptionPane.showConfirmDialog(this, message, "Sửa câu hỏi", JOptionPane.OK_CANCEL_OPTION);
        if (option == JOptionPane.OK_OPTION) {
            String newTitle = titleField.getText().trim();
            String newContent = contentArea.getText().trim();
            if (newTitle.isEmpty() || newContent.isEmpty()) {
                JOptionPane.showMessageDialog(this, "Tiêu đề và nội dung không được để trống", "Lỗi", JOptionPane.ERROR_MESSAGE);
                return;
            }
            question.setTitle(newTitle);
            question.setContent(newContent);
            boolean success = questionDAO.updateQuestion(question);
            if (success) {
                JOptionPane.showMessageDialog(this, "Cập nhật câu hỏi thành công!", "Thành công", JOptionPane.INFORMATION_MESSAGE);
                dispose();
                new QuestionDetailFrame(question.getId()).setVisible(true);
            } else {
                JOptionPane.showMessageDialog(this, "Cập nhật thất bại", "Lỗi", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    private void handleDeleteQuestion() {
        int confirm = JOptionPane.showConfirmDialog(this,
                "Bạn có chắc chắn muốn xóa câu hỏi này?",
                "Xác nhận xóa",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);
        if (confirm == JOptionPane.YES_OPTION) {
            boolean success = questionDAO.deleteQuestion(question.getId());
            if (success) {
                JOptionPane.showMessageDialog(this, "Đã xóa câu hỏi!", "Thành công", JOptionPane.INFORMATION_MESSAGE);
                dispose();
            } else {
                JOptionPane.showMessageDialog(this, "Xóa thất bại", "Lỗi", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    private void handleEditAnswer(Answer answer) {
        JTextArea contentArea = new JTextArea(answer.getContent(), 8, 40);
        contentArea.setLineWrap(true);
        contentArea.setWrapStyleWord(true);
        JScrollPane scrollPane = new JScrollPane(contentArea);
        int option = JOptionPane.showConfirmDialog(this, scrollPane, "Sửa câu trả lời", JOptionPane.OK_CANCEL_OPTION);
        if (option == JOptionPane.OK_OPTION) {
            String newContent = contentArea.getText().trim();
            if (newContent.isEmpty()) {
                JOptionPane.showMessageDialog(this, "Nội dung không được để trống", "Lỗi", JOptionPane.ERROR_MESSAGE);
                return;
            }
            answer.setContent(newContent);
            boolean success = answerDAO.updateAnswer(answer);
            if (success) {
                JOptionPane.showMessageDialog(this, "Cập nhật câu trả lời thành công!", "Thành công", JOptionPane.INFORMATION_MESSAGE);
                answers = answerDAO.getAnswersByQuestion(question.getId());
                loadAnswers();
            } else {
                JOptionPane.showMessageDialog(this, "Cập nhật thất bại", "Lỗi", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    private void handleDeleteAnswer(int answerId) {
        int confirm = JOptionPane.showConfirmDialog(this,
                "Bạn có chắc chắn muốn xóa câu trả lời này?",
                "Xác nhận xóa",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);
        if (confirm == JOptionPane.YES_OPTION) {
            boolean success = answerDAO.deleteAnswer(answerId);
            if (success) {
                JOptionPane.showMessageDialog(this, "Đã xóa câu trả lời!", "Thành công", JOptionPane.INFORMATION_MESSAGE);
                answers = answerDAO.getAnswersByQuestion(question.getId());
                loadAnswers();
            } else {
                JOptionPane.showMessageDialog(this, "Xóa thất bại", "Lỗi", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    private void startAutoRefresh() {
        autoRefreshTimer = new Timer(REFRESH_INTERVAL, e -> refreshInBackground());
        autoRefreshTimer.start();
    }
    private void stopAutoRefresh() {
        if (autoRefreshTimer != null) {
            autoRefreshTimer.stop();
            autoRefreshTimer = null;
        }
    }
    private void refreshInBackground() {
        SwingWorker<RefreshData, Void> worker = new SwingWorker<RefreshData, Void>() {
            @Override
            protected RefreshData doInBackground() throws Exception {
                Question updatedQuestion = questionDAO.findById(question.getId());
                List<Answer> updatedAnswers = answerDAO.getAnswersByQuestion(question.getId());
                int totalComments = commentDAO.getCommentCount("QUESTION", question.getId());
                for (Answer answer : updatedAnswers) {
                    totalComments += commentDAO.getCommentCount("ANSWER", answer.getId());
                }
                return new RefreshData(updatedQuestion, updatedAnswers, totalComments);
            }
            @Override
            protected void done() {
                try {
                    RefreshData data = get();
                    if (data.answers.size() > lastAnswerCount) {
                        int newAnswers = data.answers.size() - lastAnswerCount;
                        showSubtleNotification("+" + newAnswers + " câu trả lời mới!");
                    }
                    if (data.totalComments > lastCommentCount) {
                        int newComments = data.totalComments - lastCommentCount;
                        showSubtleNotification("+" + newComments + " bình luận mới!");
                    }
                    question = data.question;
                    answers = data.answers;
                    lastAnswerCount = answers.size();
                    lastCommentCount = data.totalComments;
                    answerCountLabel.setText(answers.size() + " Câu trả lời");
                    voteCountLabel.setText("Bình chọn: " + question.getVoteCount());
                    loadAnswers();
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        };
        worker.execute();
    }
    private void showSubtleNotification(String message) {
        JLabel notification = new JLabel(message);
        notification.setFont(new Font("Arial", Font.BOLD, 12));
        notification.setForeground(Color.WHITE);
        notification.setBackground(new Color(40, 167, 69));
        notification.setOpaque(true);
        notification.setBorder(BorderFactory.createEmptyBorder(5, 10, 5, 10));
        JWindow window = new JWindow(this);
        window.getContentPane().add(notification);
        window.pack();
        window.setLocationRelativeTo(this);
        Timer timer = new Timer(2000, e -> window.dispose());
        timer.setRepeats(false);
        timer.start();
        window.setVisible(true);
    }
    private static class RefreshData {
        Question question;
        List<Answer> answers;
        int totalComments;
        RefreshData(Question question, List<Answer> answers, int totalComments) {
            this.question = question;
            this.answers = answers;
            this.totalComments = totalComments;
        }
    }
}
