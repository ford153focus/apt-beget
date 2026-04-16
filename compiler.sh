#!/usr/bin/env bash
echo '#!/usr/bin/env bash' > apt-beget.sh

echo '# URL: https://github.com/ford153focus/apt-beget' >> apt-beget.sh

for helper in `find helpers -type f | sort`
do
	cat $helper >> apt-beget.sh
    printf "\n\n" >> apt-beget.sh
done 

for installer in `find installers -type f | sort`
do
	cat $installer >> apt-beget.sh
    printf "\n\n" >> apt-beget.sh
done 

cat launcher.sh >> apt-beget.sh