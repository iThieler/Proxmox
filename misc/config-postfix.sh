#!/bin/bash

source "/root/pve-global-config.sh"
source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)

bakFILE backup "/etc/aliases"
bakFILE backup "/etc/postfix/main.cf"
bakFILE backup "/etc/ssl/certs/ca-certificates.crt"

if grep "root:" /etc/aliases; then
  sed -i "s/^root:.*$/root: $mailTO/" /etc/aliases
else
  echo "root: $mailTO" >> /etc/aliases
fi
echo "root $mailFROM" >> /etc/postfix/canonical
chmod 600 /etc/postfix/canonical
echo [$mailSERVER]:$mailPORT "$mailUSER":"$mailPASS" >> /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd 
sed -i "/#/!s/\(relayhost[[:space:]]*=[[:space:]]*\)\(.*\)/\1"[$mailSERVER]:"$mailPORT""/"  /etc/postfix/main.cf
if [ $mailTLS ]; then
  postconf smtp_use_tls=yes
else
  postconf smtp_use_tls=no
fi
if ! grep "smtp_sasl_password_maps" /etc/postfix/main.cf; then
  postconf smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd > /dev/null 2>&1
fi
if ! grep "smtp_tls_CAfile" /etc/postfix/main.cf; then
  postconf smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt > /dev/null 2>&1
fi
if ! grep "smtp_sasl_security_options" /etc/postfix/main.cf; then
  postconf smtp_sasl_security_options=noanonymous > /dev/null 2>&1
fi
if ! grep "smtp_sasl_auth_enable" /etc/postfix/main.cf; then
  postconf smtp_sasl_auth_enable=yes > /dev/null 2>&1
fi 
if ! grep "sender_canonical_maps" /etc/postfix/main.cf; then
  postconf sender_canonical_maps=hash:/etc/postfix/canonical > /dev/null 2>&1
fi 
postmap /etc/postfix/sasl_passwd > /dev/null 2>&1
postmap /etc/postfix/canonical > /dev/null 2>&1
systemctl restart postfix  &> /dev/null && systemctl enable postfix  &> /dev/null
rm -rf "/etc/postfix/sasl_passwd"

# test E-Mail settings
echo -e "Dies ist eine Testnachricht, versendet durch das Konfigurationsskript von https://ithieler.github.io/Proxmox/\n\nBestätige den erhalt dieser E-Mail im Konfigurationsskript." | mail -a "From: \"HomeServer\" <${mailFROM}>" -s "[HomeServer] Testnachricht" "$mailTO"
if ! whip_yesno "JA" "NEIN" "MAILSERVER" "Es wurde eine E-Mail an >>${mailTO}<< gesendet. Wurde die E-Mail erfolgreich zugestellt? (Je nach Anbieter kann dies bis zu 15 Minuten dauern)"; then
  whip_alert "MAILSERVER" "Die Protokolldatei wird auf bekannte Fehler geprüft, es wird versucht, gefundene Fehler automatisch zu beheben.\n\nAnschließend wird erneut eine E-Mail an >>${mailTO}<< gesendet. Überprüfe auch den Spam-Ordner."
  if grep "SMTPUTF8 is required" "/var/log/mail.log"; then
    if ! grep "smtputf8_enable = no" /etc/postfix/main.cf; then
      postconf smtputf8_enable=no
      postfix reload
    fi
  fi
  echo -e "Dies ist die erneute Testnachricht, versendet durch das Konfigurationsskript von https://ithieler.github.io/Proxmox/\n\nBestätige den erhalt dieser E-Mail im Konfigurationsskript." | mail -a "From: \"HomeServer\" <${mailFROM}>" -s "[HomeServer] Testnachricht" "$mailTO"
  if ! whip_yesno "JA" "NEIN" "MAILSERVER" "Es wurde eine E-Mail an >>${mailTO}<< gesendet. Wurde die E-Mail erfolgreich zugestellt? (Je nach Anbieter kann dies bis zu 15 Minuten dauern)"; then
    whip_alert "MAILSERVER" "Das Fehlerprotokoll befindet sich in der Datei >>${mailTO}<<\nNach einer Prüfung kann dieses Skript erneut aufgerufen werden. Alle änderungen werden rückgängig gemacht."
    bakFILE recover "/etc/aliases"
    bakFILE recover "/etc/postfix/canonical"
    bakFILE recover "/etc/postfix/main.cf"
    bakFILE recover "/etc/ssl/certs/ca-certificates.crt"
    exit 1
  fi
fi

exit 0
