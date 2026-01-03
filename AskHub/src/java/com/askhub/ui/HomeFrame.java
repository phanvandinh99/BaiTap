package com.askhub.ui;
import com.askhub.dao.QuestionDAO;
import com.askhub.dao.TopicDAO;
import com.askhub.models.Question;
import com.askhub.models.Topic;
import com.askhub.models.User;
import com.askhub.utils.SessionManager;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.text.SimpleDateFormat;
import java.util.List;
public class HomeFrame extends JFrame {
    private JTable questionTable;
    private DefaultTableModel tableModel;
    private JComboBox<String> topicComboBox;
    private JTextField searchField;
    private JButton searchButton;
    private JButton askQuestionButton;
    private JButton refreshButton;
    private JButton logoutButton;
    private JButton prevPageButton;
    private JButton nextPageButton;
    private JLabel userLabel;
    private JLabel pageLabel;
    private JLabel notificationBadge;
    private QuestionDAO questionDAO;
    private TopicDAO topicDAO;
    private List<Topic> topics;
    private int currentPage = 1;
    private final int PAGE_SIZE = 20;
    private String currentSearchKeyword = "";
    private Timer autoRefreshTimer;
    private static final int REFRESH_INTERVAL = 30000;
    private int lastQuestionCount = 0;
    public HomeFrame() {
        questionDAO = new QuestionDAO();
        topicDAO = new TopicDAO();
        initComponents();
        loadTopics();
        loadQuestions();
        startAutoRefresh();
        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                stopAutoRefresh();
            }
        });
    }
    private void initComponents() {
        setTitle("AskHub - Trang chủ");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1000, 700);
        setLocationRelativeTo(null);
        JPanel mainPanel = new JPanel(new BorderLayout());
        JPanel topPanel = new JPanel(new BorderLayout());
        topPanel.setBackground(new Color(0, 102, 204));
        topPanel.setPreferredSize(new Dimension(1000, 60));
        topPanel.setBorder(BorderFactory.createEmptyBorder(10, 20, 10, 20));
        JLabel logoLabel = new JLabel("AskHub");
        logoLabel.setFont(new Font("Arial", Font.BOLD, 24));
        logoLabel.setForeground(Color.WHITE);
        notificationBadge = new JLabel("");
        notificationBadge.setFont(new Font("Arial", Font.BOLD, 12));
        notificationBadge.setForeground(Color.WHITE);
        notificationBadge.setBackground(new Color(220, 53, 69));
        notificationBadge.setOpaque(true);
        notificationBadge.setBorder(BorderFactory.createEmptyBorder(3, 8, 3, 8));
        notificationBadge.setVisible(false);
        JPanel logoPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 0));
        logoPanel.setBackground(new Color(0, 102, 204));
        logoPanel.add(logoLabel);
        logoPanel.add(notificationBadge);
        JPanel userPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 0));
        userPanel.setBackground(new Color(0, 102, 204));
        User currentUser = SessionManager.getInstance().getCurrentUser();
        userLabel = new JLabel("Xin chào, " + currentUser.getUsername());
        userLabel.setFont(new Font("Arial", Font.PLAIN, 14));
        userLabel.setForeground(Color.WHITE);
        logoutButton = new JButton("Đăng xuất");
        logoutButton.setBackground(Color.WHITE);
        logoutButton.setForeground(new Color(0, 102, 204));
        logoutButton.setFocusPainted(false);
        logoutButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        logoutButton.addActionListener(e -> handleLogout());
        userPanel.add(userLabel);
        userPanel.add(logoutButton);
        topPanel.add(logoPanel, BorderLayout.WEST);
        topPanel.add(userPanel, BorderLayout.EAST);
        JPanel filterPanel = new JPanel(new BorderLayout());
        filterPanel.setBackground(Color.WHITE);
        filterPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        JPanel topFilterPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 5));
        topFilterPanel.setBackground(Color.WHITE);
        JLabel searchLabel = new JLabel("Tìm kiếm:");
        searchLabel.setFont(new Font("Arial", Font.BOLD, 14));
        searchField = new JTextField();
        searchField.setPreferredSize(new Dimension(300, 30));
        searchField.setFont(new Font("Arial", Font.PLAIN, 14));
        searchField.addActionListener(e -> handleSearch());
        searchButton = new JButton("Tìm");
        searchButton.setBackground(new Color(0, 102, 204));
        searchButton.setForeground(Color.WHITE);
        searchButton.setFocusPainted(false);
        searchButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        searchButton.addActionListener(e -> handleSearch());
        JLabel topicLabel = new JLabel("Chủ đề:");
        topicLabel.setFont(new Font("Arial", Font.BOLD, 14));
        topicComboBox = new JComboBox<>();
        topicComboBox.setPreferredSize(new Dimension(200, 30));
        topicComboBox.addActionListener(e -> {
            currentSearchKeyword = "";
            searchField.setText("");
            currentPage = 1;
            loadQuestions();
        });
        topFilterPanel.add(searchLabel);
        topFilterPanel.add(searchField);
        topFilterPanel.add(searchButton);
        topFilterPanel.add(Box.createHorizontalStrut(20));
        topFilterPanel.add(topicLabel);
        topFilterPanel.add(topicComboBox);
        JPanel bottomFilterPanel = new JPanel(new BorderLayout());
        bottomFilterPanel.setBackground(Color.WHITE);
        JPanel actionsPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 5));
        actionsPanel.setBackground(Color.WHITE);
        askQuestionButton = new JButton("Đặt câu hỏi");
        askQuestionButton.setBackground(new Color(0, 102, 204));
        askQuestionButton.setForeground(Color.WHITE);
        askQuestionButton.setFont(new Font("Arial", Font.BOLD, 14));
        askQuestionButton.setFocusPainted(false);
        askQuestionButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        askQuestionButton.addActionListener(e -> handleAskQuestion());
        refreshButton = new JButton("Làm mới");
        refreshButton.setFocusPainted(false);
        refreshButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        refreshButton.addActionListener(e -> loadQuestions());
        actionsPanel.add(askQuestionButton);
        actionsPanel.add(refreshButton);
        JPanel paginationPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 5));
        paginationPanel.setBackground(Color.WHITE);
        prevPageButton = new JButton("← Trang trước");
        prevPageButton.setFocusPainted(false);
        prevPageButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        prevPageButton.addActionListener(e -> {
            if (currentPage > 1) {
                currentPage--;
                loadQuestions();
            }
        });
        pageLabel = new JLabel("Trang " + currentPage);
        pageLabel.setFont(new Font("Arial", Font.BOLD, 14));
        nextPageButton = new JButton("Trang sau →");
        nextPageButton.setFocusPainted(false);
        nextPageButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        nextPageButton.addActionListener(e -> {
            currentPage++;
            loadQuestions();
        });
        paginationPanel.add(prevPageButton);
        paginationPanel.add(pageLabel);
        paginationPanel.add(nextPageButton);
        bottomFilterPanel.add(actionsPanel, BorderLayout.WEST);
        bottomFilterPanel.add(paginationPanel, BorderLayout.EAST);
        filterPanel.add(topFilterPanel, BorderLayout.NORTH);
        filterPanel.add(bottomFilterPanel, BorderLayout.SOUTH);
        String[] columnNames = {"ID", "Tiêu đề", "Chủ đề", "Tác giả", "Bình chọn", "Trả lời", "Lượt xem", "Trạng thái", "Ngày đăng"};
        tableModel = new DefaultTableModel(columnNames, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        questionTable = new JTable(tableModel);
        questionTable.setFont(new Font("Arial", Font.PLAIN, 13));
        questionTable.setRowHeight(30);
        questionTable.getTableHeader().setFont(new Font("Arial", Font.BOLD, 13));
        questionTable.getTableHeader().setBackground(new Color(240, 240, 240));
        questionTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        questionTable.getColumnModel().getColumn(0).setMinWidth(0);
        questionTable.getColumnModel().getColumn(0).setMaxWidth(0);
        questionTable.getColumnModel().getColumn(0).setWidth(0);
        questionTable.getColumnModel().getColumn(1).setPreferredWidth(400);
        questionTable.getColumnModel().getColumn(2).setPreferredWidth(100);
        questionTable.getColumnModel().getColumn(3).setPreferredWidth(100);
        questionTable.getColumnModel().getColumn(4).setPreferredWidth(60);
        questionTable.getColumnModel().getColumn(5).setPreferredWidth(70);
        questionTable.getColumnModel().getColumn(6).setPreferredWidth(60);
        questionTable.getColumnModel().getColumn(7).setPreferredWidth(100);
        questionTable.getColumnModel().getColumn(8).setPreferredWidth(150);
        questionTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = questionTable.getSelectedRow();
                    if (row != -1) {
                        int questionId = (int) tableModel.getValueAt(row, 0);
                        openQuestionDetail(questionId);
                    }
                }
            }
        });
        JScrollPane scrollPane = new JScrollPane(questionTable);
        scrollPane.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        mainPanel.add(topPanel, BorderLayout.NORTH);
        mainPanel.add(filterPanel, BorderLayout.SOUTH);
        mainPanel.add(scrollPane, BorderLayout.CENTER);
        add(mainPanel);
    }
    private void loadTopics() {
        topics = topicDAO.getAllTopics();
        topicComboBox.removeAllItems();
        topicComboBox.addItem("Tất cả chủ đề");
        for (Topic topic : topics) {
            topicComboBox.addItem(topic.getName());
        }
    }
    private void handleSearch() {
        currentSearchKeyword = searchField.getText().trim();
        currentPage = 1;
        loadQuestions();
    }
    private void loadQuestions() {
        tableModel.setRowCount(0);
        List<Question> questions;
        if (!currentSearchKeyword.isEmpty()) {
            questions = questionDAO.searchQuestions(currentSearchKeyword, currentPage, PAGE_SIZE);
        } else {
            int selectedTopicIndex = topicComboBox.getSelectedIndex();
            if (selectedTopicIndex <= 0) {
                questions = questionDAO.getAllQuestions(currentPage, PAGE_SIZE);
            } else {
                Topic selectedTopic = topics.get(selectedTopicIndex - 1);
                questions = questionDAO.getQuestionsByTopic(selectedTopic.getId(), currentPage, PAGE_SIZE);
            }
        }
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        for (Question q : questions) {
            Object[] row = {
                q.getId(),
                q.getTitle(),
                q.getTopicName(),
                q.getUsername(),
                q.getVoteCount(),
                q.getAnswerCount(),
                q.getViewCount(),
                q.getStatus(),
                sdf.format(q.getCreatedAt())
            };
            tableModel.addRow(row);
        }
        pageLabel.setText("Trang " + currentPage);
        prevPageButton.setEnabled(currentPage > 1);
        nextPageButton.setEnabled(questions.size() >= PAGE_SIZE);
    }
    private void handleAskQuestion() {
        CreateQuestionDialog dialog = new CreateQuestionDialog(this, topics);
        dialog.setVisible(true);
        if (dialog.isSuccess()) {
            loadQuestions();
        }
    }
    private void openQuestionDetail(int questionId) {
        QuestionDetailFrame detailFrame = new QuestionDetailFrame(questionId);
        detailFrame.setVisible(true);
        detailFrame.addWindowListener(new java.awt.event.WindowAdapter() {
            @Override
            public void windowClosed(java.awt.event.WindowEvent windowEvent) {
                loadQuestions();
            }
        });
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
        SwingWorker<Integer, Void> worker = new SwingWorker<Integer, Void>() {
            @Override
            protected Integer doInBackground() throws Exception {
                return questionDAO.getTotalQuestionCount();
            }
            @Override
            protected void done() {
                try {
                    int currentCount = get();
                    if (lastQuestionCount > 0 && currentCount > lastQuestionCount) {
                        int newQuestions = currentCount - lastQuestionCount;
                        notificationBadge.setText("+" + newQuestions + " mới");
                        notificationBadge.setVisible(true);
                        showNotification("Có " + newQuestions + " câu hỏi mới!");
                    }
                    lastQuestionCount = currentCount;
                    loadQuestions();
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        };
        worker.execute();
    }
    private void showNotification(String message) {
        JOptionPane optionPane = new JOptionPane(message, JOptionPane.INFORMATION_MESSAGE);
        JDialog dialog = optionPane.createDialog(this, "Thông báo");
        Timer closeTimer = new Timer(3000, e -> dialog.dispose());
        closeTimer.setRepeats(false);
        closeTimer.start();
        dialog.setModal(false);
        dialog.setVisible(true);
    }
    private void handleLogout() {
        stopAutoRefresh();
        int confirm = JOptionPane.showConfirmDialog(this,
                "Bạn có chắc chắn muốn đăng xuất?",
                "Xác nhận đăng xuất",
                JOptionPane.YES_NO_OPTION);
        if (confirm == JOptionPane.YES_OPTION) {
            SessionManager.getInstance().logout();
            dispose();
            SwingUtilities.invokeLater(() -> {
                LoginFrame loginFrame = new LoginFrame();
                loginFrame.setVisible(true);
            });
        }
    }
}
