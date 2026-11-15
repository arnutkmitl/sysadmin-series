#!/bin/bash
# ตรวจไฟล์เว็บก่อน build: ต้องมี title และตัวแทน version/commit ครบ
set -e
f=site/index.html
grep -q '<title>' "$f"
grep -q '@VERSION@' "$f"
grep -q '@COMMIT@' "$f"
echo "test passed: $f"
