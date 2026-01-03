package com.askhub.ui;
import com.askhub.dao.UserDAO;
import com.askhub.models.User;
import com.askhub.utils.SessionManager;
import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
public class RegisterFrame extends JFrame {
    private JTextField usernameField;
    private JTextField emailField;
    private JTextField fullNameField;
    private JPasswordField passwordField;
    private JPasswordField confirmPasswordField;
    private JButton registerButton;
    private JButton backToLoginButton;
    private UserDAO userDAO;
    public RegisterFrame() {
        userDAO = new UserDAO();
        initComponents();
    }
    private void initComponents() {
        setTitle("AskHub - Đăng ký");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(450, 550);
        setLocationRelativeTo(null);
        setResizable(false);
        JPanel mainPanel = new JPanel();
        mainPanel.setLayout(new BorderLayout());
        mainPanel.setBackground(Color.WHITE);
        JPanel headerPanel = new JPanel();
        headerPanel.setBackground(new Color(0, 102, 204));
        headerPanel.setPreferredSize(new Dimension(450, 80));
        JLabel titleLabel = new JLabel("Tạo tài khoản");
        titleLabel.setFont(new Font("Arial", Font.BOLD, 28));
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
        gbc.gridwidth = 2;
        gbc.gridy = 0;
        formPanel.add(createLabel("Tên đăng nhập:"), gbc);
        gbc.gridy = 1;
        usernameField = createTextField();
        formPanel.add(usernameField, gbc);
        gbc.gridy = 2;
        formPanel.add(createLabel("Email:"), gbc);
        gbc.gridy = 3;
        emailField = createTextField();
        formPanel.add(emailField, gbc);
        gbc.gridy = 4;
        formPanel.add(createLabel("Họ và tên:"), gbc);
        gbc.gridy = 5;
        fullNameField = createTextField();
        formPanel.add(fullNameField, gbc);
        gbc.gridy = 6;
        formPanel.add(createLabel("Mật khẩu:"), gbc);
        gbc.gridy = 7;
        passwordField = new JPasswordField();
        passwordField.setFont(new Font("Arial", Font.PLAIN, 14));
        passwordField.setPreferredSize(new Dimension(300, 35));
        formPanel.add(passwordField, gbc);
        gbc.gridy = 8;
        formPanel.add(createLabel("Xác nhận mật khẩu:"), gbc);
        gbc.gridy = 9;
        confirmPasswordField = new JPasswordField();
        confirmPasswordField.setFont(new Font("Arial", Font.PLAIN, 14));
        confirmPasswordField.setPreferredSize(new Dimension(300, 35));
        formPanel.add(confirmPasswordField, gbc);
        gbc.gridy = 10;
        gbc.insets = new Insets(20, 5, 5, 5);
        JPanel buttonPanel = new JPanel(new GridLayout(1, 2, 10, 0));
        buttonPanel.setBackground(Color.WHITE);
        registerButton = new JButton("Đăng ký");
        registerButton.setFont(new Font("Arial", Font.BOLD, 14));
        registerButton.setBackground(new Color(0, 102, 204));
        registerButton.setForeground(Color.WHITE);
        registerButton.setFocusPainted(false);
        registerButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        registerButton.addActionListener(this::handleRegister);
        backToLoginButton = new JButton("Quay lại đăng nhập");
        backToLoginButton.setFont(new Font("Arial", Font.PLAIN, 14));
        backToLoginButton.setBackground(Color.WHITE);
        backToLoginButton.setForeground(new Color(0, 102, 204));
        backToLoginButton.setBorder(BorderFactory.createLineBorder(new Color(0, 102, 204), 2));
        backToLoginButton.setFocusPainted(false);
        backToLoginButton.setCursor(new Cursor(Cursor.HAND_CURSOR));
        backToLoginButton.addActionListener(this::handleBackToLogin);
        buttonPanel.add(registerButton);
        buttonPanel.add(backToLoginButton);
        formPanel.add(buttonPanel, gbc);
        mainPanel.add(headerPanel, BorderLayout.NORTH);
        mainPanel.add(formPanel, BorderLayout.CENTER);
        add(mainPanel);
    }
    private JLabel createLabel(String text) {
        JLabel label = new JLabel(text);
        label.setFont(new Font("Arial", Font.BOLD, 14));
        return label;
    }
    private JTextField createTextField() {
        JTextField field = new JTextField();
        field.setFont(new Font("Arial", Font.PLAIN, 14));
        field.setPreferredSize(new Dimension(300, 35));
        return field;
    }
    private void handleRegister(ActionEvent e) {
        String username = usernameField.getText().trim();
        String email = emailField.getText().trim();
        String fullName = fullNameField.getText().trim();
        String password = new String(passwordField.getPassword());
        String confirmPassword = new String(confirmPasswordField.getPassword());
        if (username.isEmpty() || email.isEmpty() || fullName.isEmpty() ||
            password.isEmpty() || confirmPassword.isEmpty()) {
            showError("Tất cả các trường đều bắt buộc");
            return;
        }
        if (!username.matches("^[a-zA-Z0-9_]{3,20}$")) {
            showError("Tên đăng nhập phải từ 3-20 ký tự (chữ cái, số, gạch dưới)");
            return;
        }
        if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
            showError("Định dạng email không hợp lệ");
            return;
        }
        if (password.length() < 6) {
            showError("Mật khẩu phải có ít nhất 6 ký tự");
            return;
        }
        if (!password.equals(confirmPassword)) {
            showError("Mật khẩu xác nhận không khớp");
            return;
        }
        if (userDAO.findByUsername(username) != null) {
            showError("Tên đăng nhập đã tồn tại");
            return;
        }
        if (userDAO.findByEmail(email) != null) {
            showError("Email đã được sử dụng");
            return;
        }
        User user = new User(username, email, password, fullName);
        boolean success = userDAO.createUser(user);
        if (success) {
            JOptionPane.showMessageDialog(this,
                    "Tạo tài khoản thành công!",
                    "Thành công",
                    JOptionPane.INFORMATION_MESSAGE);
            SessionManager.getInstance().login(user);
            dispose();
            SwingUtilities.invokeLater(() -> {
                HomeFrame homeFrame = new HomeFrame();
                homeFrame.setVisible(true);
            });
        } else {
            showError("Đăng ký thất bại. Vui lòng thử lại.");
        }
    }
    private void handleBackToLogin(ActionEvent e) {
        dispose();
        SwingUtilities.invokeLater(() -> {
            LoginFrame loginFrame = new LoginFrame();
            loginFrame.setVisible(true);
        });
    }
    private void showError(String message) {
        JOptionPane.showMessageDialog(this, message, "Lỗi", JOptionPane.ERROR_MESSAGE);
    }
}
