# /etc/dovecot/sieve/junk.sieve  ทำงานก่อน filter ของผู้ใช้ทุกคน (sieve_before)
require ["fileinto"];

# SpamAssassin ให้คะแนนตั้งแต่ 5 หรือโดเมนผู้ส่งประกาศ p=quarantine แต่อีเมลไม่ผ่าน DMARC
if anyof (header :contains "X-Spam-Flag" "YES",
          header :contains "Authentication-Results" "dmarc=fail (p=quarantine") {
  fileinto "Junk";
  stop;
}
