-- Create database
CREATE DATABASE IF NOT EXISTS todo_app;
USE todo_app;

-- Create todos table
CREATE TABLE IF NOT EXISTS todos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task VARCHAR(255) NOT NULL,
    completed BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some sample data
INSERT INTO todos (task, completed) VALUES 
('Complete AWS infrastructure setup', 0),
('Deploy LAMP stack application', 0),
('Test high availability', 0),
('Configure CloudWatch monitoring', 0);