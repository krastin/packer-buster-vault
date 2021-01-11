# check if needed binaries exist
EXECUTABLES = curl jq sort egrep tail
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

# if no version given, use the lates open source one
ifndef $VERSION
    VERSION = $(shell curl -sL https://releases.hashicorp.com/vault/index.json | jq -r '.versions[].version' | sort -V | egrep -v 'beta|rc|alpha|ent' | tail -1)
    $(warning vault version undefined - assuming latest oss version v.${VERSION})
endif

default: all

all: buster-vault-${VERSION}.box

buster-vault-${VERSION}.box: template.json scripts/provision.sh http/preseed.cfg
	@echo "Building buster-vault v.${VERSION}"
	packer validate template.json
	packer build -force -only=buster-vault -var version='${VERSION}' template.json
	#vagrant box add --force --name buster-vault --box-version ${VERSION} ./buster-vault-${VERSION}.box  

publish: buster-vault-${VERSION}.box
ifneq (,$(findstring ent,$(VERSION)))
	@echo publishing ENT version to krastin/buster-vault-enterprise
	vagrant cloud publish --box-version $(firstword $(subst +, ,$(VERSION))) --force --release krastin/buster-vault-enterprise $(firstword $(subst +, ,$(VERSION))) virtualbox buster-vault-${VERSION}.box
else
	@echo publishing OSS version to krastin/buster-vault
	vagrant cloud publish --box-version ${VERSION} --force --release krastin/buster-vault ${VERSION} virtualbox buster-vault-${VERSION}.box
endif

test: buster-vault-${VERSION}.box
	bundle exec kitchen test default-krastin-buster-vault

.PHONY: clean 
clean:
	-bundle exec kitchen destroy
	-vagrant box remove -f buster-vault --provider virtualbox
	-rm -fr output-*/ *.box
