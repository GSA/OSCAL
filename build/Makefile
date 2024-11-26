SHELL:=/usr/bin/env bash

.PHONY: help
# Run "make" or "make help" to get a list of user targets
# Adapted from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?##.*$$' $(MAKEFILE_LIST) | awk 'BEGIN { \
	 FS = ":.*?## "; \
	 printf "\033[1m%-30s\033[0m %s\n", "TARGET", "DESCRIPTION" \
	} \
	{ printf "\033[32m%-30s\033[0m %s\n", $$1, $$2 }'

.PHONY: build
build: artifacts checks archives ## Run all pipelines

.PHONY: artifacts
artifacts: schemas ## Generate all artifacts

.PHONY: test
test: validate-content

.PHONY: checks
checks: linkcheck validate ## Run all tests and checks

.PHONY: dependencies
dependencies: node_modules ## Ensure dependencies have been installed

node_modules: package.json package-lock.json
	npm ci

.PHONY: clean
clean: clean-schemas clean-linkcheck clean-archives ## Remove all generated content

METASCHEMA_CLI:=npx oscal-cli metaschema
RESOLVE_PROFILE:=npx oscal-cli resolve-profile
SRC_DIR:=../src/metaschema
# Contains all OSCAL metaschema modules, including those without exported roots
ALL_METASCHEMAS:=$(shell find $(SRC_DIR) -name '*_metaschema.xml')
# Contains the OSCAL metaschema modules that contain root assemblies
METASCHEMAS:=$(shell find $(SRC_DIR) -name '*_metaschema.xml' -a ! -name '*common*' -a ! -name '*metadata*')
GENERATED_DIR:=generated

#####################
# Schema Generation #
#####################

XSD_OUTPUTS:=$(patsubst $(SRC_DIR)/%_metaschema.xml,$(GENERATED_DIR)/%_schema.xsd,$(METASCHEMAS))
JSONSCHEMA_OUTPUTS:=$(patsubst $(SRC_DIR)/%_metaschema.xml,$(GENERATED_DIR)/%_schema.json,$(METASCHEMAS))

$(GENERATED_DIR)/%_schema.json $(GENERATED_DIR)/%_schema.xsd: $(SRC_DIR)/%_metaschema.xml
	@mkdir -p $(GENERATED_DIR)
	$(METASCHEMA_CLI) generate-schema --as=json $< $(GENERATED_DIR)/$*_schema.json --overwrite
	$(METASCHEMA_CLI) generate-schema --as=xml $< $(GENERATED_DIR)/$*_schema.xsd --overwrite
	
.PHONY: schemas
schemas: $(XSD_OUTPUTS) $(JSONSCHEMA_OUTPUTS) ## Generate the schemas

.PHONY: clean-schemas
clean-schemas: ## Remove generated schemas
	rm -fr $(GENERATED_DIR)/*_schema.*


######################
# Archive Generation #
######################

RELEASE:=SNAPSHOT
ZIP_ARCHIVE:=$(GENERATED_DIR)/oscal-$(RELEASE).zip
TARBZ2_ARCHIVE:=$(GENERATED_DIR)/oscal-$(RELEASE).tar.bz2
ARCHIVE_TEMP_DIR:=$(GENERATED_DIR)/archive_temp

.PHONY: archives
archives: $(ZIP_ARCHIVE) ## Archive schemas

$(ZIP_ARCHIVE) $(TARBZ2_ARCHIVE): schemas
	@echo Generating archive
	mkdir -p $(ARCHIVE_TEMP_DIR)/{{json,xml}/schema,metaschema}
	cp ../src/release/release-readme.txt "$(ARCHIVE_TEMP_DIR)/README.txt"
	cp $(XSD_OUTPUTS) "$(ARCHIVE_TEMP_DIR)/xml/schema"
	cp $(ALL_METASCHEMAS) "$(ARCHIVE_TEMP_DIR)/metaschema"
	cp $(JSONSCHEMA_OUTPUTS) "$(ARCHIVE_TEMP_DIR)/json/schema"

	(cd "$(ARCHIVE_TEMP_DIR)" && zip -r $(abspath $(ZIP_ARCHIVE)) .)
	tar -jcvf "$(TARBZ2_ARCHIVE)" -C "$(ARCHIVE_TEMP_DIR)" .

	@echo Removing temporary archive staging directory $(ARCHIVE_TEMP_DIR)
    # rm -fr $(ARCHIVE_TEMP_DIR)

.PHONY: clean-archives
clean-archives: ## Clean generated archive and schemas
	rm -fr $(ARCHIVE_TEMP_DIR)
	rm -fr $(ZIP_ARCHIVE) $(TARBZ2_ARCHIVE)

#######################
# Markdown Link Check #
#######################

LINKCHECK_OUTPUT:=$(GENERATED_DIR)/mlc_report.log
LINKCHECK_CONFIG:=markdown-link-check.json

.PHONY: linkcheck
linkcheck: $(LINKCHECK_OUTPUT) ## Perform Markdown link checking

# WARNING: will fail if locally deleted markdown files are not staged.
# 1. cd into the parent directory
# 2. list all markdown files known to git
# 3. Pass the files as an argument to the markdown link checker
# 4. Write the log to a file
# 5. Exit with a failure if any of the link checker invocations failed
$(LINKCHECK_OUTPUT): node_modules $(LINKCHECK_CONFIG)
	@mkdir -p $(GENERATED_DIR)
	@echo Checking Markdown links...
	cd ..; git ls-files -z "*.md" | \
		xargs -0n1 npx --prefix build/ markdown-link-check -c build/$(LINKCHECK_CONFIG) | \
		tee build/$(LINKCHECK_OUTPUT); \
	exit $${PIPESTATUS[1]}

.PHONY: clean-linkcheck
clean-linkcheck: ## Remove linkcheck log
	rm -fr $(LINKCHECK_OUTPUT)

#######################
# Artifact Validation #
#######################

.PHONY: validate
validate: validate-jsonschemas validate-xsds validate-composition ## Validate all generated content

.PHONY: validate-content
validate-content: $(METASCHEMAS) ## Validate all generated content
	npm run test

.PHONY: validate-jsonschemas
validate-jsonschemas: node_modules $(JSONSCHEMA_OUTPUTS) ## Validate generated JSON Schemas
	@echo Validating generated JSON Schemas
	npx ajv compile -c "ajv-formats" -s "$(GENERATED_DIR)/*_schema.json"

.PHONY: validate-xsds
validate-xsds: $(XSD_OUTPUTS) ## Validate generated XSD files
	@echo Validting generated XSDs
	xmllint --noout $(XSD_OUTPUTS)

VALIDATE_COMPOSITION_TARGETS:=$(patsubst $(SRC_DIR)/oscal_%_metaschema.xml,validate-composition-%,$(METASCHEMAS))

.PHONY: validate-composition
validate-composition: $(VALIDATE_COMPOSITION_TARGETS) ## Validate source metaschemas

validate-composition-%:
	@echo Performing composition validation of the $* model via cli
	$(METASCHEMA_CLI) validate $(SRC_DIR)/oscal_$*_metaschema.xml

###################
# Utility Targets #
###################

.PHONY: configure
configure: ## install oscal CLI
	npm install
	npx oscal@2.0.7-rc5 use 2.4.0-SNAPSHOT


# All artifacts typically included in a release
RELEASE_ARTIFACTS:=$(XSD_OUTPUTS) $(JSONSCHEMA_OUTPUTS) $(ZIP_ARCHIVE) $(TARBZ2_ARCHIVE)

# This target is used by OSCAL-Reference to generate meta-redirects for release assets
.PHONY: list-release-artifacts
list-release-artifacts: ## Print out a list of all artifacts typically included in an OSCAL release
	@echo $(RELEASE_ARTIFACTS)
