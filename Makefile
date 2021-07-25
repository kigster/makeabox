# vim: ft=make
# vim: ts=8
# vim: sw=8
#
# This Makefile is provided as a complement to the scripts in the ./bin folder.
#
# WARNING: remember to use actual tabs in this file, not spaces, otherwise
# the Makefile will not be valid.

.PHONY: 	help start


BIN_PATH	:= $(shell pwd)/bin
MAKEABOX_HOME	:= $(shell if [[ -d ${HOME}/.MAKEABOX ]]; then echo ${HOME}/.MAKEABOX; else echo ${MAKEABOX_HOME}; fi)
PATH 		:= $(PATH):$(BIN_PATH)

red		:= \033[0;31m
yellow		:= \033[0;33m
blue 		:= \033[0;34m
green		:= \033[0;35m
clear		:= \033[0m

help:		## Prints help message auto-generated from the comments.
		@grep -E '^[a-zA-Z_-]+:.*?##.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?##"}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

start-prod:	## Starts server in production mode
		@bash -c " \
			export RAILS_ENV=production; \
			bundle exec rake assets:precompile; \
			bundle exec rake puma-ctl start \
			"



