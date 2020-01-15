%.mk: %.tree
	@\mkdir -p $(dir $@)
	@\awk 'BEGIN { \
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
	@\awk 'BEGIN { \
			print "define " toupper("$(basename $(notdir $@))") "_RECIPE" \
		} \
		{ \
			if(NF == 2) { \
				if ($$1 ~ /\/$$/) { \
					print "\t@\\mkdir -p $$1" $$1 " $${LF}" \
				} else {\
					print "\t@\\mkdir -p $$(dir $$1" $$1 ") $${LF}" \
				} \
				print "\t@\\cp $$2/" $$2 " $$1" $$1 " $${LF}" \
			} else if ($$1 ~ /^-/) { \
				print "\t@\\rm -rf $$1" substr($$1, 2) " $${LF}" \
			} else { \
				print "\t@\\mkdir -p $$1" $$1 " $${LF}" \
			} \
		} \
		END { \
			print "endef" \
		}' $< >> $@.tmp
	@\mv $@.tmp $@

ifndef LF
define LF


endef
endif

