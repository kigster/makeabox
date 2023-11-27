# vim: ft=make
# vim: tabstop=8
# vim: shiftwidth=8
# vim: noexpandtab


.PHONY:  clean dd-start-agent dd-stop-agent dd-mac-setup dd-launchd-verify fixtures generate-local generate help test-debug test


SHELL 		:= $(shell if [[ -x /opt/homebrew/bin/bash ]]; then echo "/opt/homebrew/bin/bash"; else echo "/bin/bash"; fi)
CURRENT_OS	:= $(shell uname -s | tr '[:upper:]' '[:lower:]')
CURRENT_PATH	:= $(shell dirname "$(MAKEFILE_PATH)")
CURRENT_DIR 	:= $(notdir $(patsubst %/,%,$(dir $(MAKEFILE_PATH))))
HOSTNAME	:= $(shell hostname -f)
DD_API_KEY	:= $(shell echo $(DD_API_KEY))
GIT_SHA		:= $(shell git rev-parse --short HEAD)
GIT_BRANCH	:= $(shell git branch --show-current)
HOME		:= $(shell echo $(HOME))
ENVRC		:= $(shell echo $(CURRENT_PATH)/.envrc)
RAILS_ENV	:= $(shell echo $(RAILS_ENV))
RUBY_VERSION    := $(shell cat .ruby-version | tr -d '\n')

PFX="─────────────────────────────━━━┫ "
YLW=\e[0;30;43m ▶︎
GRN=\e[0;30;42m ▶︎
RED=\e[0;37;41m ▶︎
BLU=\e[0;37;44m ▶︎
CLR=\e[0m\n
FMT=%80.80s

ifndef RAILS_ENV
RAILS_ENV := "development"
endif

##—— TASKS ————————————————————————————————————————————————————————————————————————————————————

help:	   	## Prints help message auto-generated from the comments.
		@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "	\033[36m%-20s\033[0m %s\n", $$1, $$2}'

brew: 		## Installs Homebrew if on OS-X
		@command -v brew >/dev/null || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		@command -v brew >/dev/null && { \
			printf "$(BLU)$(FMT)$(CLR)" "Please wait while we ensure your brew packages are up to date..."; \
			brew bundle --no-upgrade ; }
		@printf "$(YLW)$(FMT)$(CLR)" "Starting Redis..."
		@brew services start redis
		@printf "$(YLW)$(FMT)$(CLR)" "Starting Memcached..."
		@brew services start memcached
		@bash -c "\
			if [[ $$( ps -ef | egrep 'redis|memcached' | grep -c -v grep ) -eq 2 ]]; then \
				printf \"$(GRN)$(FMT)$(CLR)\" \"Redis and Memcached are OK.\" ; \
			else \
				printf \"$(RED)$(FMT)$(CLR)\" \"Either Redis or Memcached did not start.\"; \
			fi "

ruby: 		brew ## Installs Ruby if needed
		@bash -c "\
			if [[ -d $(HOME)/.rbenv/versions/$(RUBY_VERSION) ]] ; then \
				printf \"$(GRN)$(FMT)$(CLR)\" \"Ruby $(RUBY_VERSION) is already installed.\";  \
			else \
				printf \"$(BLU)$(FMT)$(CLR)\" \"Installing Ruby $(RUBY_VERSION) with YJIT enabled.\"; \
				ruby-build $(RUBY_VERSION) $(HOME)/.rbenv/versions/$(RUBY_VERSION) -- --enable-yjit; \
			fi; \
			rbenv global $(RUBY_VERSION); \
			"

bundle: 	ruby ## Run the local test suite
		@printf "$(YLW)$(FMT)$(CLR)" "Installing bundled gems..."
		@bundle check || bundle install -j 12 --quiet

test: 		bundle ## Run the local test suite
		@printf "$(YLW)$(FMT)$(CLR)" "Running RSpecs..."
		@bundle exec rspec --force-color

lint: 		bundle ## Runs rubocop
		@printf "$(YLW)$(FMT)$(CLR)" "Running Rubocop..."
		@bash -c "bundle exec rubocop --color"

lint-fix: 	bundle ## Runs rubocop with auto-correct
		@bash -c "bundle exec rubocop -a --color; @bundle exec rspec --force-color"

lint-fix-all: 	bundle ## Runs rubocop with a more dangerous auto-correct
		bundle exec rubocop -A --color; @bundle exec rspec


pre-commit: 	test lint  ## Runs rspec and rubocop before the commit

git-status:	## Ensures the local repo is clean
		@bash -c "\
			if [[ -n \"$$(git status --porcelain)\" ]]; then \
 				printf \"$(RED)$(FMT)$(CLR)\" \"Your local repo is not clean. Please commit or stash your changes.\"; \
 				exit 1; \
			else \
 				printf \"$(GRN)$(FMT)$(CLR)\" \"Your local repo is clean.\"; \
			fi"
deploy:		bundle pre-commit git-status ## Deploy makeabox to production using Capistrano
		@printf "$(YLW)$(FMT)$(CLR)" "Deploying makeabox to production..."
		@bash -c "bundle exec cap production deploy"

deploy-quick:	bundle ## Deploy makeabox to production using Capistrano, skips tests and git status
		@printf "$(YLW)$(FMT)$(CLR)" "Deploying makeabox to production..."
		@bash -c "bundle exec cap production deploy"

puma:		bundle ## Start the local Puma server and the browser to localhost:3000
		@printf "$(YLW)$(FMT)$(CLR)" "Starting Puma..."
		@bash -c "sleep 5; open http://localhost:3000" &
		@bash -c "bundle exec rails s"

sidekiq:	bundle ## Start the local Puma server and the browser to localhost:3000
		@printf "$(YLW)$(FMT)$(CLR)" "Starting Sidekiq..."
		bundle exec sidekiq -C config/sidekiq.yml

app: 		bundle ## Starts the entire app
		@printf "$(YLW)$(FMT)$(CLR)" "Starting Puma and Sidekiq via Foreman..."
		@bundle exec foreman start -f Procfile

