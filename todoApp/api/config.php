<?php
// Database configuration
$db_host = 'localhost'; // In production, this would be the Aurora MySQL endpoint
$db_name = 'todo_app';
$db_user = 'todo_user';
$db_pass = 'todo_password'; // In production, use AWS Secrets Manager

// Create database connection
try {
    $conn = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['error' => 'Connection failed: ' . $e->getMessage()]);
    exit;
}
?>