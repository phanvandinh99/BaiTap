package com.askhub.ui;
import com.askhub.dao.UserDAO;
import com.askhub.models.User;
import com.askhub.utils.SessionManager;
import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
public class LoginFrame extends JFrame {
    private JTextField usernameField;
    private JPasswordField passwordField;
    private JButton loginButton;
    private JButton registerButton;
    private UserDAO userDAO;
    public LoginFrame() {
        userDAO = new UserDAO();
        initComponents();
    }
    private void initComponents() {
        setTitle("AskHub - Đăng nhập");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(450, 350);
        setLocationRelativeTo(null);
        setResizable(false);
        JPanel mainPanel = new JPanel();
        mainPanel.setLayout(new BorderLayout());
        mainPanel.setBackground(Color.WHITE);
        JPanel headerPanel = new JPanel();
        headerPanel.setBackground(new Color(0, 102, 204));
        headerPanel.setPreferredSize(new Dimension(450, 80));
        JLabel titleLabel = new JLabel("AskHub");
        titleLabel.setFont(new Font("Arial", Font.BOLD, 32));
        titleLabel.setForeground(Color.WHITE);
        headerPanel.add(titleLabel);
        JPanel formPanel = new JPanel();
        formPanel.setLayout(new GridBagLayout());
        formPanel.setBackground(Color.WHITE);
        formPanel.setBorder(BorderFactory.createEmptyBorder(20, 40, 20, 40));
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.gridwidth = 2;
        JLabel usernameLabel = new JLabel("Tên đăng nhập:");
        usernameLabel.setFont(new Font("Arial", Font.BOLD, 14));
        formPanel.add(usernameLabel, gbc);
        gbc.gridy = 1;
        usernameField = new JTextField();
        usernameField.setFont(new Font("Arial", Font.PLAIN, 14));
        usernameField.setPreferredSize(new Dimension(300, 35));
        formPanel.add(usernameField, gbc);
        gbc.gridy = 2;
        JLabel passwordLabel = new JLabel("Mật khẩu:");
        passwordLabel.setFont(new Font("Arial", Font.BOLD, 14));
        formPanel.add(passwordLabel, gbc);
        gbc.gridy = 3;
        passwordField = new JPasswordField();
        passwordField.setFont(new Font("Arial", Font.PLAIN, 14));
        passwordField.setPreferredSize(new Dimension(300, 35));
        formPanel.add(passwordField, gbc);
        gbc.gridy = 4;
        gbc.insets = new Insets(20, 5, 5, 5);
        JPanel buttonPanel = new JPanel(new GridLayout(1, 2, 10, 0));
        buttonPanel.setBackground(Color.WHITE);
        loginButton = new JButton("Đăng nhập");
        loginButton.setFont(new Font("Arial", Font.BOLD, 14));
        loginButton.setBackground(new Color(0, 102, 204));
        loginButton.setForeground(Color.WHITE);
        loginButton.setFocusPainted(false);
        loginButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        loginButton.addActionListener(this::handleLogin);
        registerButton = new JButton("Đăng ký");
        registerButton.setFont(new Font("Arial", Font.PLAIN, 14));
        registerButton.setBackground(Color.WHITE);
        registerButton.setForeground(new Color(0, 102, 204));
        registerButton.setBorder(BorderFactory.createLineBorder(new Color(0, 102, 204), 2));
        registerButton.setFocusPainted(false);
        registerButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        registerButton.addActionListener(this::handleRegister);
        buttonPanel.add(loginButton);
        buttonPanel.add(registerButton);
        formPanel.add(buttonPanel, gbc);
        mainPanel.add(headerPanel, BorderLayout.NORTH);
        mainPanel.add(formPanel, BorderLayout.CENTER);
        add(mainPanel);
        passwordField.addActionListener(this::handleLogin);
    }
    private void handleLogin(ActionEvent e) {
        String username = usernameField.getText().trim();
        String password = new String(passwordField.getPassword());
        if (username.isEmpty() || password.isEmpty()) {
            JOptionPane.showMessageDialog(this,
                    "Vui lòng nhập tên đăng nhập và mật khẩu",
                    "Lỗi",
                    JOptionPane.ERROR_MESSAGE);
            return;
        }
        User user = userDAO.authenticate(username, password);
        if (user != null) {
            SessionManager.getInstance().login(user);
            JOptionPane.showMessageDialog(this,
                    "Chào mừng, " + user.getUsername() + "!",
                    "Thành công",
                    JOptionPane.INFORMATION_MESSAGE);
            dispose();
            SwingUtilities.invokeLater(() -> {
                HomeFrame homeFrame = new HomeFrame();
                homeFrame.setVisible(true);
            });
        } else {
            JOptionPane.showMessageDialog(this,
                    "Tên đăng nhập hoặc mật khẩu không đúng",
                    "Đăng nhập thất bại",
                    JOptionPane.ERROR_MESSAGE);
            passwordField.setText("");
        }
    }
    private void handleRegister(ActionEvent e) {
        dispose();
        SwingUtilities.invokeLater(() -> {
            RegisterFrame registerFrame = new RegisterFrame();
            registerFrame.setVisible(true);
        });
    }
}
