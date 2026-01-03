package com.askhub.ui;
import com.askhub.dao.QuestionDAO;
import com.askhub.models.Question;
import com.askhub.models.Topic;
import com.askhub.utils.SessionManager;
import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.util.List;
public class CreateQuestionDialog extends JDialog {
    private JTextField titleField;
    private JTextArea contentArea;
    private JComboBox<String> topicComboBox;
    private JButton submitButton;
    private JButton cancelButton;
    private List<Topic> topics;
    private QuestionDAO questionDAO;
    private boolean success = false;
    public CreateQuestionDialog(Frame parent, List<Topic> topics) {
        super(parent, "Đặt câu hỏi", true);
        this.topics = topics;
        this.questionDAO = new QuestionDAO();
        initComponents();
    }
    private void initComponents() {
        setSize(600, 500);
        setLocationRelativeTo(getParent());
        setResizable(false);
        JPanel mainPanel = new JPanel(new BorderLayout());
        mainPanel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));
        JPanel formPanel = new JPanel(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.gridx = 0;
        gbc.gridwidth = 2;
        gbc.gridy = 0;
        JLabel titleLabel = new JLabel("Tiêu đề:");
        titleLabel.setFont(new Font("Arial", Font.BOLD, 14));
        formPanel.add(titleLabel, gbc);
        gbc.gridy = 1;
        titleField = new JTextField();
        titleField.setFont(new Font("Arial", Font.PLAIN, 14));
        titleField.setPreferredSize(new Dimension(500, 35));
        formPanel.add(titleField, gbc);
        gbc.gridy = 2;
        JLabel topicLabel = new JLabel("Chủ đề:");
        topicLabel.setFont(new Font("Arial", Font.BOLD, 14));
        formPanel.add(topicLabel, gbc);
        gbc.gridy = 3;
        topicComboBox = new JComboBox<>();
        topicComboBox.setFont(new Font("Arial", Font.PLAIN, 14));
        topicComboBox.setPreferredSize(new Dimension(500, 35));
        for (Topic topic : topics) {
            topicComboBox.addItem(topic.getName());
        }
        formPanel.add(topicComboBox, gbc);
        gbc.gridy = 4;
        JLabel contentLabel = new JLabel("Chi tiết câu hỏi:");
        contentLabel.setFont(new Font("Arial", Font.BOLD, 14));
        formPanel.add(contentLabel, gbc);
        gbc.gridy = 5;
        gbc.fill = GridBagConstraints.BOTH;
        gbc.weighty = 1.0;
        contentArea = new JTextArea();
        contentArea.setFont(new Font("Arial", Font.PLAIN, 13));
        contentArea.setLineWrap(true);
        contentArea.setWrapStyleWord(true);
        JScrollPane scrollPane = new JScrollPane(contentArea);
        scrollPane.setPreferredSize(new Dimension(500, 200));
        formPanel.add(scrollPane, gbc);
        gbc.gridy = 6;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.weighty = 0;
        gbc.insets = new Insets(20, 5, 5, 5);
        JPanel buttonPanel = new JPanel(new GridLayout(1, 2, 10, 0));
        submitButton = new JButton("Đăng câu hỏi");
        submitButton.setFont(new Font("Arial", Font.BOLD, 14));
        submitButton.setBackground(new Color(0, 102, 204));
        submitButton.setForeground(Color.WHITE);
        submitButton.setFocusPainted(false);
        submitButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        submitButton.addActionListener(this::handleSubmit);
        cancelButton = new JButton("Hủy");
        cancelButton.setFont(new Font("Arial", Font.PLAIN, 14));
        cancelButton.setFocusPainted(false);
        cancelButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        cancelButton.addActionListener(e -> dispose());
        buttonPanel.add(submitButton);
        buttonPanel.add(cancelButton);
        formPanel.add(buttonPanel, gbc);
        mainPanel.add(formPanel, BorderLayout.CENTER);
        add(mainPanel);
    }
    private void handleSubmit(ActionEvent e) {
        String title = titleField.getText().trim();
        String content = contentArea.getText().trim();
        int topicIndex = topicComboBox.getSelectedIndex();
        if (title.isEmpty()) {
            JOptionPane.showMessageDialog(this,
                    "Vui lòng nhập tiêu đề",
                    "Lỗi",
                    JOptionPane.ERROR_MESSAGE);
            return;
        }
        if (content.isEmpty()) {
            JOptionPane.showMessageDialog(this,
                    "Vui lòng nhập chi tiết câu hỏi",
                    "Lỗi",
                    JOptionPane.ERROR_MESSAGE);
            return;
        }
        if (topicIndex < 0) {
            JOptionPane.showMessageDialog(this,
                    "Vui lòng chọn chủ đề",
                    "Lỗi",
                    JOptionPane.ERROR_MESSAGE);
            return;
        }
        Topic selectedTopic = topics.get(topicIndex);
        int userId = SessionManager.getInstance().getCurrentUserId();
        Question question = new Question(userId, selectedTopic.getId(), title, content);
        boolean created = questionDAO.createQuestion(question);
        if (created) {
            JOptionPane.showMessageDialog(this,
                    "Đăng câu hỏi thành công!",
                    "Thành công",
                    JOptionPane.INFORMATION_MESSAGE);
            success = true;
            dispose();
        } else {
            JOptionPane.showMessageDialog(this,
                    "Đăng câu hỏi thất bại. Vui lòng thử lại.",
                    "Lỗi",
                    JOptionPane.ERROR_MESSAGE);
        }
    }
    public boolean isSuccess() {
        return success;
    }
}
