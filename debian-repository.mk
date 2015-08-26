SHELL=sh

ifneq ($(wildcard config.mk),)
include config.mk
endif
DIRECTORIES?=.
GPG_KEY?=
GPG_KEY_PASSWORD?=

BIN_DIRS=$(shell find $(DIRECTORIES) -type d -name 'binary-*')
SRC_DIRS=$(shell find $(DIRECTORIES) -type d -name sources)
PACKAGES=$(addsuffix /Packages,$(BIN_DIRS))
SOURCES=$(addsuffix /Sources,$(SRC_DIRS))
APT_FTP_CONF=$(shell find $(DIRECTORIES) -type f -name apt-ftp.conf)
PACKAGES_GZ=$(addsuffix .gz,$(PACKAGES))
SOURCES_GZ=$(addsuffix .gz,$(SOURCES))
RELEASES=$(subst apt-ftp.conf,Release,$(APT_FTP_CONF))
RELEASES_GPG=$(addsuffix .gpg,$(RELEASES))
ifneq (,$(GPG_KEY))
GPG_KEY_OPT=-u $(GPG_KEY)
endif

all: $(PACKAGES_GZ) $(SOURCES_GZ) $(RELEASES_GPG)

$(PACKAGES_GZ): $(PACKAGES)
$(SOURCES_GZ): $(SOURCES)
$(RELEASES): $(APT_FTP_CONF)
$(RELEASES_GPG): $(RELEASES)

$(PACKAGES):
	$(info Scan packages $@)
	$(call init_repository,$@)
	@( cd $(repo) && dpkg-scanpackages $(relative_dir) > $(relative_dir)/$(notdir $@) )

$(SOURCES):
	$(info Scan sources $@)
	$(call init_repository,$@)
	@( cd $(repo) && dpkg-scansources $(relative_dir) > $(relative_dir)/$(notdir $@) )

%.gz: %
	gzip -9c $< > $@

%/Release: %/apt-ftp.conf
	$(info Generates $@)
	$(call init_repository,$@)
	@( cd $(repo) && apt-ftparchive -c $(relative_dir)/$$(basename $<) release $(relative_dir) > $(relative_dir)/$(notdir $@) )

%.gpg: %
	$(info GPG signature $@)
	$(eval GPG_COMMAND=gpg --sign --armor --detach-sign --yes $(GPG_KEY_OPT) -o $@ $<)
ifeq (,$(GPG_KEY_PASSWORD))
	@$(GPG_COMMAND)
else
	@LANG=C expect -c 'spawn $(GPG_COMMAND); \
		expect "Enter passphrase:" { send "$(GPG_KEY_PASSWORD)\r" }; \
		sleep 1' > /dev/null
endif

clean:
	rm -f $(PACKAGES_GZ) $(PACKAGES) $(SOURCES_GZ) $(SOURCES) $(RELEASES_GPG) $(RELEASES)

define init_repository
	$(eval repo=$(firstword $(subst /, ,$1)))
	$(eval relative_dir=$(subst $(repo)/,,$(dir $1)))
endef

.PHONY: all clean
