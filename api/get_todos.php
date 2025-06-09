<?php
header('Content-Type: application/json');
require_once 'config.php';

try {
    $stmt = $conn->prepare("SELECT * FROM todos ORDER BY created_at DESC");
    $stmt->execute();
    $todos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode($todos);
} catch(PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>