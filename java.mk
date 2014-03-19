TOUCH_DIR ?= .
JFLAGS ?= 
BUILD_DIR ?= build
GENERATED_DIR ?= generated
DIST_DIR ?= dist
SOURCE_VERSION ?= 1.7
TARGET_VERSION ?= $(SOURCE_VERSION)
JAVAC ?= javac
JAR ?= $(shell dirname `which $(JAVAC)`)/jar
JAVA ?= $(shell dirname `which $(JAVAC)`)/java
SRC_DIRS ?= src
ECLIPSE_WORKSPACE_DIRECTORY ?= eclipse-workspace
PROCESSOR_FACTORIES_MODULES ?=
PROCESSOR_FACTORIES_COTS_JAR ?=
COMPILE_FILTER ?= 

CALLBACKS = 

.PHONY: compile jar eclipse
compile:
	$(eval CALLBACKS += COMPILE)
jar:
	$(eval CALLBACKS += BUILD_JAR)
eclipse:
	$(eval CALLBACKS += ECLIPSE_PROJECT)

ifeq (,$(findstring n,$(MAKEFLAGS)))


$(shell mkdir --parent $(TOUCH_DIR))

define COMPILE
	@echo Compile module $(TARGET) $(shell [ ! -z "$(DEPENDENCIES)" ] && echo wich depends on $(shell echo $(DEPENDENCIES)|sed -r 's/\s+/, /g'))
	$(eval CLASS_PATH_OPT = $(shell if [ ! -z "$(DEPENDENCIES_$(TARGET))" ]; then echo -classpath $(shell echo $(DEPENDENCIES_$(TARGET))|sed -r 's/\s+/:/g'); fi))
	$(eval GENERATED_PATH = $(GENERATED_DIR)/$(MODULE))
	-rm -rf $(GENERATED_PATH)
	-mkdir --parent $(GENERATED_PATH) $(BUILD_PATH) dist
	$(eval PROCESSOR_PATH = $(addprefix $(BUILD_DIR)/,$(PROCESSOR_FACTORIES_MODULES)))
	$(eval PROCESSOR_PATH += $(PROCESSOR_FACTORIES_JAR))
	$(eval PROCESSOR_PATH = $(shell if [ ! -z "$(PROCESSOR_PATH)" ]; then echo $(shell echo $(PROCESSOR_PATH)|sed -r 's/\s+/:/g'); fi))

	$(eval PROCESSOR_OPT = $(shell ([ $(MODULE) = "net.aeten.core" ] || [ $(MODULE) = "net.jcip.annotations" ]) && echo -proc:none || echo -processorpath $(PROCESSOR_PATH)))

	$(eval CLASSES =)
	@echo Pre $(TARGET) start
	$(call pre.$(TARGET))
	@echo Pre $(TARGET) end
	$(eval CLASSES += $(shell [ -z $(SOURCE_PATH) ] || find $(SOURCE_PATH) -type f $(COMPILE_FILTER) -name '*.java' -and -print))
	$(eval COMPILE_FILTER =)
	$(foreach class, $(CLASSES), \
		@echo find class $(class)>/dev/null $(eol) \
	)
	$(JAVAC) $(JFLAGS) $(CLASS_PATH_OPT) -d $(BUILD_PATH) -s $(GENERATED_PATH) -source $(SOURCE_VERSION) -target $(TARGET_VERSION) $(PROCESSOR_OPT) -sourcepath $(SOURCE_PATH) $(CLASSES)
	$(foreach resource, $(shell find $(SOURCE_PATH) -type f ! -name \*.java|sed "s@$(SOURCE_PATH)@@"), \
		-mkdir --parent $(BUILD_PATH)/`dirname $(resource)` $(eol) \
		cp $(SOURCE_PATH)/$(resource) $(BUILD_PATH)/`dirname $(resource)` $(eol) \
	)
	@echo Post $(TARGET) start
	$(call post.$(TARGET))
	@echo Post $(TARGET) end
endef

define BUILD_JAR
	$(JAR) cf $(DIST_DIR)/$(MODULE).jar -C $(BUILD_PATH) .
	$(info JAR $(DIST_DIR)/$(MODULE).jar built)
endef

define ECLIPSE_PROJECT
	@-mkdir --parent $(ECLIPSE_WORKSPACE_DIRECTORY)/$(MODULE)/src
	$(call ECLIPSE_PROJECT_FILE)
	$(call ECLIPSE_CLASSPATH_FILE)
	$(call ECLIPSE_FACTORYPATH_FILE)
	$(call ECLIPSE_SETTINGS_FILES)
endef

define eol


endef


define ECLIPSE_PROJECT_FILE
@echo '<?xml version="1.0" encoding="UTF-8"?>\
<projectDescription>\
        <name>$(MODULE)</name>\
        <comment></comment>\
        <projects>\
        </projects>\
        <buildSpec>\
                <buildCommand>\
                        <name>org.eclipse.jdt.core.javabuilder</name>\
                        <arguments>\
                        </arguments>\
                </buildCommand>\
        </buildSpec>\
        <natures>\
                <nature>org.eclipse.jdt.core.javanature</nature>\
        </natures>\
        <linkedResources>\
                <link>\
                        <name>src</name>\
                        <type>2</type>\
                        <locationURI>$(abspath $(SOURCE_PATH))</locationURI>\
                </link>\
        </linkedResources>\
</projectDescription>' >  $(ECLIPSE_WORKSPACE_DIRECTORY)/$(MODULE)/.project
endef


define ECLIPSE_CLASSPATH_FILE
@echo '<?xml version="1.0" encoding="UTF-8"?>\
<classpath>\
        <classpathentry kind="src" path="src"/>\
        <classpathentry exported="true" kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>\
$(foreach dependence, $(DEPENDENCIES_$(TARGET)),\
        <classpathentry combineaccessrules="false" kind="src" path="/$(subst $(BUILD_DIR)/,,$(dependence))"/>\
)\
        <classpathentry kind="output" path="bin"/>\
</classpath>' > $(ECLIPSE_WORKSPACE_DIRECTORY)/$(MODULE)/.classpath
endef


# update_file (file, line)
define update_file
	@sh -c "(([ -f '$1' ] && ! grep --fixed-strings -q '$2' '$1') || [ ! -f '$1' ]) && echo '$2' >> '$1'; exit 0"
endef


define ECLIPSE_SETTINGS_FILES
@-mkdir --parent $(ECLIPSE_WORKSPACE_DIRECTORY)/$(MODULE)/.settings\
$(eval file = $(ECLIPSE_WORKSPACE_DIRECTORY)/$(MODULE)/.settings/org.eclipse.jdt.apt.core.prefs)
$(call update_file,$(file),eclipse.preferences.version=1)
$(call update_file,$(file),org.eclipse.jdt.apt.aptEnabled=true)
$(call update_file,$(file),org.eclipse.jdt.apt.genSrcDir=.apt_generated)
$(call update_file,$(file),org.eclipse.jdt.apt.reconcileEnabled=true)

$(eval file = $(ECLIPSE_WORKSPACE_DIRECTORY)/$(MODULE)/.settings/org.eclipse.jdt.core.prefs)
$(call update_file,$(file),eclipse.preferences.version=1)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.codegen.inlineJsrBytecode=enabled)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.codegen.methodParameters=do not generate)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.codegen.targetPlatform=$(TARGET_VERSION))
$(call update_file,$(file),org.eclipse.jdt.core.compiler.codegen.unusedLocal=preserve)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.compliance=$(SOURCE_VERSION))
$(call update_file,$(file),org.eclipse.jdt.core.compiler.debug.lineNumber=generate)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.debug.localVariable=generate)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.debug.sourceFile=generate)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.problem.assertIdentifier=error)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.problem.enumIdentifier=error)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.processAnnotations=enabled)
$(call update_file,$(file),org.eclipse.jdt.core.compiler.source=$(SOURCE_VERSION))
endef


define ECLIPSE_FACTORYPATH_FILE
@echo '<factorypath>\
$(foreach processor_factory_module, $(PROCESSOR_FACTORIES_MODULES),\
	<factorypathentry kind="EXTJAR" id="$(abspath $(DIST_DIR)/$(processor_factory_module).jar)" enabled="true" runInBatchMode="false"/>\
)\
$(foreach processor_factory_jar, $(PROCESSOR_FACTORIES_COTS_JAR),\
	<factorypathentry kind="EXTJAR" id="$(processor_factory_jar)" enabled="true" runInBatchMode="false"/>\
)\
	</factorypath>' > $(ECLIPSE_WORKSPACE_DIRECTORY)/$(MODULE)/.factorypath
endef


$(MODULES):: %: $(TOUCH_DIR)/%

.SECONDEXPANSION:
$(addprefix $(TOUCH_DIR)/,$(MODULES)): %:  $$(addprefix $(TOUCH_DIR)/,$$(shell make -prn|awk '/^$$(subst $(TOUCH_DIR)/,,$$@)::/ && NF > 1 && sub($$$$1,"",$$$$0) { print $$$$0 }'))
	$(eval TARGET = $(patsubst $(TOUCH_DIR)/%,%,$@))
	$(eval DEPENDENCIES = $(subst $(TOUCH_DIR)/,,$^))
	$(eval SOURCE_PATH = $(shell find $(SRC_DIRS) -maxdepth 1 -name \*.$(TARGET) | awk 'BEGIN {source=""} {if (length(source) == 0 || length($$0) < length(source)) {source=$$0}} END {print source "/"}'))
	$(eval MODULE = $(shell basename $(SOURCE_PATH)))
	$(eval CLASS_PATH =)
	$(foreach dependence, $(DEPENDENCIES), \
		$(eval DEPENDENCE = $(shell basename $$(find $(SRC_DIRS) -maxdepth 1 -name \*.$(dependence) | awk 'BEGIN {source=""} {if (length(source) == 0 || length($$0) < length(source)) {source=$$0}} END {print source "/"}'))) \
		$(eval DEPENDENCIES_$(TARGET) += $(BUILD_DIR)/$(DEPENDENCE) $(DEPENDENCIES_$(dependence))) \
	)
	$(eval DEPENDENCIES_$(TARGET) = $(shell echo $(DEPENDENCIES_$(TARGET))|sed -r 's/\s+/\n/g'|sort|uniq))
	$(eval BUILD_PATH = $(BUILD_DIR)/$(MODULE))
	$(foreach callback, $(CALLBACKS),\
		$(call $(callback))\
	)
	@touch $@

endif # n in MAKEFLAGS

