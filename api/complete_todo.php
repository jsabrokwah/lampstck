<?php
header('Content-Type: application/json');
require_once 'config.php';

// Check if ID is provided
if (!isset($_POST['id']) || empty($_POST['id'])) {
    echo json_encode(['success' => false, 'error' => 'Todo ID is required']);
    exit;
}

$id = (int)$_POST['id'];

try {
    // First, get the current status
    $stmt = $conn->prepare("SELECT completed FROM todos WHERE id = :id");
    $stmt->bindParam(':id', $id);
    $stmt->execute();
    $todo = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$todo) {
        echo json_encode(['success' => false, 'error' => 'Todo not found']);
        exit;
    }
    
    // Toggle the completed status
    $newStatus = $todo['completed'] ? 0 : 1;
    
    $stmt = $conn->prepare("UPDATE todos SET completed = :status WHERE id = :id");
    $stmt->bindParam(':status', $newStatus);
    $stmt->bindParam(':id', $id);
    $stmt->execute();
    
    echo json_encode(['success' => true]);
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>