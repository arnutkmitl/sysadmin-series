<?php
// /srv/site/note.php  หน้าทดสอบว่า PHP เขียนไฟล์ลง uploads ได้หรือไม่ (หัวข้อ 3.3)
$f = __DIR__ . "/uploads/note-" . date("His") . ".txt";
if (file_put_contents($f, "hello\n") === false) {
    http_response_code(500);
    echo "เขียนไม่ได้: " . error_get_last()["message"] . "\n";
} else {
    echo "เขียนแล้ว: " . basename($f) . "\n";
}
