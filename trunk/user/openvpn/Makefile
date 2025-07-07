SRC_NAME=openvpn-2.5.9
SRC_URL=https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/openvpn-2.5.9.tar.gz

PATCHES=02-tunnelblick-openvpn_xorpatch-a.diff \
        03-tunnelblick-openvpn_xorpatch-b.diff \
        04-tunnelblick-openvpn_xorpatch-c.diff \
        05-tunnelblick-openvpn_xorpatch-d.diff \
        06-tunnelblick-openvpn_xorpatch-e.diff

CFLAGS += -ffunction-sections -fdata-sections -fvisibility=hidden
LDFLAGS += -Wl,--gc-sections

all: download extract patch config_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)

download:
	@if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 --timeout=20 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL) || exit 1; \
	fi

extract:
	@if [ ! -d $(SRC_NAME) ]; then \
		tar -xf $(SRC_NAME).tar.gz || exit 1; \
		patch -d $(SRC_NAME) -p1 -i ../openvpn-orig.patch || exit 1; \
	fi

patch:
	@if [ ! -f $(SRC_NAME)/.patched ]; then \
		cd $(SRC_NAME); \
		echo "Downloading and applying patches..."; \
		for patch in $(PATCHES); do \
			wget "https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/$$patch" || exit 1; \
			git apply "$$patch" || exit 1; \
		done; \
		touch .patched; \
	fi

config_test:
	@if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		$(MAKE) configure && touch config_done; \
	fi

configure:
	( cd $(SRC_NAME) ; \
	autoreconf -fi ; \
	IFCONFIG=/sbin/ifconfig \
	ROUTE=/sbin/route \
	NETSTAT=/bin/netstat \
	LIBNL_GENL_CFLAGS=-I$(STAGEDIR)/include/libnl3 \
	LIBNL_GENL_LIBS="-L$(STAGEDIR)/lib -lnl-genl-3" \
	LIBCAPNG_CFLAGS=-I$(STAGEDIR)/include \
	LIBCAPNG_LIBS="-L$(STAGEDIR)/lib -lcap-ng" \
	OPENSSL_CFLAGS=-I$(STAGEDIR)/include/openssl \
	OPENSSL_LIBS="-L$(STAGEDIR)/lib -lssl -lcrypto" \
	./configure \
		--prefix=/usr \
		--disable-debug \
		--disable-plugins \
		--disable-pkcs11 \
		--disable-ofb-cfb \
		--disable-selinux \
		--disable-systemd \
		--disable-iproute2 \
		--disable-unit-tests \
		--disable-management \
		--disable-lz4 \
		--enable-small \
		--enable-fragment \
		--enable-lzo \
		--with-crypto-library=openssl \
		--with-sysroot=$(STAGEDIR) \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

clean:
	@if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done $(SRC_NAME)/.patched

romfs:
	$(ROMFSINST) $(SRC_NAME)/src/openvpn/openvpn /usr/sbin/openvpn
	$(ROMFSINST) -p +x /usr/bin/openvpn-cert.sh
	$(ROMFSINST) -p +x vpncli.sh /usr/bin/vpncli.sh
	$(ROMFSINST) -p +x scripts/restart_vpncli.sh /usr/sbin/restart_vpncli.sh
	$(ROMFSINST) /scripts/restart_vpncli.sh /etc/storage/vpncli_script.sh