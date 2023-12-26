#!/bin/bash

CURL=/usr/bin/curl
SCRIPT=discord_bot.sh
SCRIPT_URL=https://raw.githubusercontent.com/jrwashburn/mina-node-discord-bot/use-systemd/$SCRIPT

# prompt for webhook url
while true; do
  read -p "Enter Discord Webhook URL: " WEBHOOK_URL
  if [ -z "$WEBHOOK_URL" ]; then
    echo "Webhook URL cannot be empty."
  else
    break
  fi
done

# change to user home directory
cd ~

# download bot script
$CURL -fsSL $SCRIPT_URL > $SCRIPT

# sustitute webhook url
sed -i "s@ENTER_DISCORD_WEBHOOK_URL_HERE@$WEBHOOK_URL@g" $SCRIPT

# make the script executable
chmod +x $SCRIPT

sudo mv $SCRIPT /usr/local/bin/$SCRIPT

read -n1 -r -p "Would you like to run under systemd instead of cron? (y/n) " YESNO
echo
if [ $YESNO = "y" ] || [ $YESNO = "Y" ] ; then
  sudo tee /etc/systemd/user/mina-discord-bot.service &>/dev/null << E-O-F
[Unit]
Description=Mina Discord Bot Service
After=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=15
ExecStart=/usr/local/bin/$SCRIPT 

[Install]
WantedBy=default.target
E-O-F

  sudo tee /etc/systemd/user/mina-discord-bot.timer &>/dev/null << E-O-F
  [Unit]
Description=Mina Discord Bot Timer

[Timer]
OnCalendar=00/0:15
Unit=mina-discord-bot.service
Persistent=true

[Install]
WantedBy=default.target
E-O-F

else
  # add the script to cronjob
  (crontab -l | grep $PWD/$SCRIPT) || (crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/$SCRIPT >/dev/null 2>&1") | crontab -
fi

# execute the script
/usr/local/bin/$SCRIPT
