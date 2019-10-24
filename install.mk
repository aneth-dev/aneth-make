ifeq (${INSTALL_VERBOSE},yes)
INSTALL_VPRFX :=
else
INSTALL_VPRFX := @
endif

%.mk: %.tree
	${INSTALL_VPRFX}\mkdir -p $(dir $@)
	${INSTALL_VPRFX}\awk 'BEGIN { \
			printf toupper("$(basename $(notdir $@))") "_DEPS = $@" \
		} \
		{ \
			if (NF == 2) { \
				printf " " $$2 \
			} \
		} \
		END { \
			print "" \
		}' $< > $@.tmp
	${INSTALL_VPRFX}\awk 'BEGIN { \
			print "define " toupper("$(basename $(notdir $@))") "_RECIPE" \
		} \
		{ \
			if(NF == 2) { \
				if ($$1 ~ /\/$$/) { \
					print "\t$${INSTALL_VPRFX}\\mkdir -p $$1" $$1 " $${LF}" \
				} else {\
					print "\t$${INSTALL_VPRFX}\\mkdir -p $$(dir $$1" $$1 ") $${LF}" \
				} \
				print "\t$${INSTALL_VPRFX}\\cp $$2/" $$2 " $$1" $$1 " $${LF}" \
			} else if ($$1 ~ /^-/) { \
				print "\t$${INSTALL_VPRFX}\\rm -rf $$1" substr($$1, 2) " $${LF}" \
			} else { \
				print "\t$${INSTALL_VPRFX}\\mkdir -p $$1" $$1 " $${LF}" \
			} \
		} \
		END { \
			print "endef" \
		}' $< >> $@.tmp
	${INSTALL_VPRFX}\mv $@.tmp $@

define LF


endef

