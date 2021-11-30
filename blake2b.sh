# Credit https://gist.githubusercontent.com/CryptoCream/0f395fac3430a4525ebfb7243fbbc0e0/raw/c0723d95dc2a03c6e9985b15e0fcfd3e1c593a09/blake2b.py
#curl https://bootstrap.pypa.io/pip/2.7/get-pip.py | python
git clone https://github.com/BLAKE2/libb2.git
cd libb2
./autogen.sh
./configure
make
sudo make install
