<?php
$dsn = sprintf('mysql:host=%s;dbname=%s', getenv('DB_HOST'), getenv('DB_NAME'));
try {
    $pdo = new PDO($dsn, getenv('DB_USER'), getenv('DB_PASSWORD'));
    $ver = $pdo->query('SELECT VERSION()')->fetchColumn();
    echo "PHP " . PHP_VERSION . " -> MySQL $ver\n";
} catch (PDOException $e) {
    http_response_code(500);
    echo "DB error: " . $e->getMessage() . "\n";
}
