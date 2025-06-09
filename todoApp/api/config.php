<?php
// Database configuration
$db_host = 'todo-app-lamp-stack-v2-auroradbcluster-h5r6dywvlzyy.cluster-cdgs4qkmwl1f.eu-west-1.rds.amazonaws.com'; // Aurora MySQL endpoint
$db_name = 'todo_app';
$db_user = 'admin'; // Using the username from CloudFormation parameters
$db_pass = ''; // Password should be set during deployment, not stored in code

// Create database connection
try {
    $conn = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    // Log the error for debugging
    error_log('Database connection failed: ' . $e->getMessage());
    echo json_encode(['error' => 'Connection failed: ' . $e->getMessage()]);
    exit;
}
?>