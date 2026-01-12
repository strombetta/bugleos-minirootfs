#
# Copyright (c) Sebastiano Trombetta. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

include mk/paths.mk

# define quite / verbose
ifeq ($(V),1)
Q :=
else
Q := @
endif

# $(call do_step, TAG, LABEL, COMMAND, LOGFILE)
define do_step
	$(Q)printf "  %-8s %s\n" "$(1)" "$(2)"
	$(Q){ $(3); } > "$(LOGS_DIR)/$(strip $(4)).log" 2>&1 || { \
	printf "  %-8s %s [FAILED] (see %s)\n" "$(1)" "$(2)" "$(LOGS_DIR)/$(strip $(4)).log"; \
	exit 1; }
endef

# $(call do_download, LABEL, COMMAND, LOGFILE)
define do_download
	$(call do_step,DOWNLOAD,$(1),$(2),$(3))
endef

# $(call do_verify, LABEL, COMMAND, LOGFILE)
define do_verify
	$(call do_step,VERIFY,$(1),$(2),$(3))
endef

# $(call do_unpack, LABEL, COMMAND, LOGFILE)
define do_unpack
	$(call do_step,UNPACK,$(1),$(2),$(3))
endef

# Quote a shell string safely for: sh -c '<string>'
# It wraps the whole command in single quotes and escapes any embedded single quote.
# Example: abc'def  ->  'abc'"'"'def'
define sh_quote
'$(subst ','"'"',$(1))'
endef

# $(call with_host_env, COMMAND) Host-only, deterministic PATH
define with_host_env
	env -i HOME="$$HOME" SHELL="/bin/sh" LANG="C" LC_ALL="C" \
		PATH="/usr/bin:/bin" \
		sh -eu -c $(call sh_quote,$(1))
endef

# $(call with_cross_env, COMMAND) Cross-enabled, deterministic PATH (host first, then your toolchains)
define with_cross_env
	env -i HOME="$$HOME" SHELL="/bin/sh" LANG="C" LC_ALL="C" \
		PATH="/usr/bin:/bin:$(TOOLCHAIN_ROOT)/bin:$(TOOLCHAIN_ROOT)/$(TARGET)/bin:$(STAGE1_TOOLCHAIN_ROOT)/bin:$(STAGE1_TOOLCHAIN_ROOT)/$(TARGET)/bin" \
		sh -eu -c $(call sh_quote,$(1))
endef