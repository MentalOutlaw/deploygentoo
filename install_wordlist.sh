mkdir /usr/share/wordlist
git clone https://github.com/digination/dirbuster-ng`
cd dirbuster-ng/
cp -a wordlists/. /usr/share/wordlist/
###This is a big one over 1GB
#git clone https://github.com/kennyn510/wpa2-wordlists.git
#cd wpa2-wordlists/
#cp -a Wordlists/. /usr/share/wordlist/
#cp -a PlainText/. /usr/share/wordlist/
#cd ..
#rm -rf wpa2-wordlists/
rm -rf dirbuster-ng/
