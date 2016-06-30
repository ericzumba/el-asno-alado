include make/git/Makefile

ORG:=vivareal

PROJECT_NAME:=asno
include make/pro/Makefile

ENV:=dev
include make/env/Makefile

CONTAINER_ID:=$(ENV)
DSL:=cfndsl
DSL_TARGET_DIR:=target
ARTIFACT:=$(DSL_TARGET_DIR)/$(DSL).tar.gz
include make/doc/Makefile

$(ARTIFACT): artifact
artifact: $(DSL_TARGET_DIR) 
		tar -zcf $(ARTIFACT) \
			$(DSL)/bin \
			$(DSL)/lib \
			$(DSL)/Gemfile \
			$(DSL)/$(DSL).gemspec

$(DSL_TARGET_DIR):
	mkdir -p $(DSL_TARGET_DIR)

run: image
	docker run \
		--rm \
		-ti $(IMAGE_NAME)
