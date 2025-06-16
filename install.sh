sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/local/share/newsletter

sudo rm /usr/local/bin/newsletter || true
sudo cp bin/newsletter /usr/local/bin/newsletter
sudo chmod +x /usr/local/bin/newsletter

sudo rm -r /usr/local/share/newsletter || true
sudo cp -r lib/ /usr/local/share/newsletter
