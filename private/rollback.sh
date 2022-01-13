sudo systemctl stop codex.target
sudo mv /opt/codex /opt/codex-bad
sudo mv /opt/codex-old /opt/codex
sudo systemctl start codex.target