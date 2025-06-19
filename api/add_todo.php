<?php
header('Content-Type: application/json');
require_once 'config.php';

// Check if task is provided
if (!isset($_POST['task']) || empty($_POST['task'])) {
    echo json_encode(['success' => false, 'error' => 'Task is required']);
    exit;
}

$task = trim($_POST['task']);

try {
    $stmt = $conn->prepare("INSERT INTO todos (task, completed) VALUES (:task, 0)");
    $stmt->bindParam(':task', $task, PDO::PARAM_STR);
    $stmt->execute();
    
    $id = $conn->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'todo' => [
            'id' => $id,
            'task' => $task,
            'completed' => 0,
            'created_at' => date('Y-m-d H:i:s')
        ]
    ]);
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>