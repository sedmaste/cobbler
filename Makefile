MESSAGESPOT=po/messages.pot

all: rpms

clean:
	-rm -f pod2htm*.tmp
	-rm -f cobbler*.gz cobbler*.rpm MANIFEST
	-rm -rf cobbler-* dist build
	-rm -rf *~
	-rm -rf rpm-build/
	#-rm -f docs/cobbler.1.gz
	#-rm -f docs/cobbler.html
	#-rm -f po/messages.pot*

manpage:
	pod2man --center="cobbler" --release="" ./docs/cobbler.pod | gzip -c > ./docs/cobbler.1.gz
	pod2html ./docs/cobbler.pod > ./docs/cobbler.html
 
test: 
	-mkdir -p /tmp/cobbler_test_bak
	-cp /var/lib/cobbler/distros*  /tmp/cobbler_test_bak
	-cp /var/lib/cobbler/profiles* /tmp/cobbler_test_bak
	-cp /var/lib/cobbler/systems*  /tmp/cobbler_test_bak
	-cp /var/lib/cobbler/repos*    /tmp/cobbler_test_bak
	-cp /var/lib/cobbler/repos*    /tmp/cobbler_test_bak
	python tests/tests.py
	-cp /tmp/cobbler_test_bak/* /var/lib/cobbler

test2:
	python tests/multi.py	

build: clean updatewui messages
	python setup.py build -f

install: clean manpage
	python setup.py install -f

devinstall:
	cp /var/lib/cobbler/settings /tmp/cobbler_settings
	cp /etc/cobbler/auth.conf /tmp/cobbler_auth.conf
	cp /etc/cobbler/modules.conf /tmp/cobbler_modules.conf
	-cp /var/www/cgi-bin/cobbler/.htpasswd /tmp/cobbler_htpasswd
	make install
	cp /tmp/cobbler_settings /var/lib/cobbler/settings
	cp /tmp/cobbler_auth.conf /etc/cobbler/auth.conf
	cp /tmp/cobbler_modules.conf /etc/cobbler/modules.conf
	-cp /tmp/cobbler_htpasswd /var/www/cgi-bin/cobbler/.htpasswd
	find /var/lib/cobbler/triggers | xargs chmod +x
	chown -R apache /var/www/cobbler 
	chown -R apache /var/www/cgi-bin/cobbler	
	chmod -R +x /var/www/cobbler/web

webtest: devinstall
	/sbin/service cobblerd restart
	/sbin/service httpd restart

sdist: clean messages updatewui
	python setup.py sdist

messages: cobbler/*.py
	xgettext -k_ -kN_ -o $(MESSAGESPOT) cobbler/*.py
	sed -i'~' -e 's/SOME DESCRIPTIVE TITLE/cobbler/g' -e 's/YEAR THE PACKAGE'"'"'S COPYRIGHT HOLDER/2007 Red Hat, Inc. /g' -e 's/FIRST AUTHOR <EMAIL@ADDRESS>, YEAR/Michael DeHaan <mdehaan@redhat.com>, 2007/g' -e 's/PACKAGE VERSION/cobbler $(VERSION)-$(RELEASE)/g' -e 's/PACKAGE/cobbler/g' $(MESSAGESPOT)


rpms: clean manpage sdist
	mkdir -p rpm-build
	cp dist/*.gz rpm-build/
	rpmbuild --define "_topdir %(pwd)/rpm-build" \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define '_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm' \
	--define "_specdir %{_topdir}" \
	--define "_sourcedir  %{_topdir}" \
	-ba cobbler.spec

srpm: manpage sdist
	mkdir -p rpm-build
	cp dist/*.gz rpm-build/
	rpmbuild --define "_topdir %(pwd)/rpm-build" \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define '_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm' \
	--define "_specdir %{_topdir}" \
	--define "_sourcedir  %{_topdir}" \
	-bs --nodeps cobbler.spec

updatewui:
	cheetah-compile ./webui_templates/master.tmpl
	-(rm ./webui_templates/*.bak)
	mv ./webui_templates/master.py ./cobbler/webui

eraseconfig:
	-rm /var/lib/cobbler/distros*
	-rm /var/lib/cobbler/profiles*
	-rm /var/lib/cobbler/systems*
	-rm /var/lib/cobbler/repos*
