default: help

RUBY_IMAGE ?= ruby:3.3-bookworm
BUNDLER_VERSION ?= 2.5.23
CONTAINER_NAME ?= hajnalmt-blog
BUILD_CONTAINER_NAME ?= hajnalmt-blog-build
JEKYLL_SETUP = gem install bundler -v $(BUNDLER_VERSION) && git config --global --add safe.directory /srv/jekyll && bundle _$(BUNDLER_VERSION)_ install

build: ## builds a _site directory
	docker run --rm --name "$(BUILD_CONTAINER_NAME)" --volume="$$PWD:/srv/jekyll" --workdir="/srv/jekyll" $(RUBY_IMAGE) bash -lc "$(JEKYLL_SETUP) && bundle _$(BUNDLER_VERSION)_ exec jekyll build"

up: ## starts a live reloading container
	docker run --rm --name "$(CONTAINER_NAME)" --volume="$$PWD:/srv/jekyll" --workdir="/srv/jekyll" -p 4000:4000 -p 35729:35729 $(RUBY_IMAGE) bash -lc "$(JEKYLL_SETUP) && bundle _$(BUNDLER_VERSION)_ exec jekyll serve --livereload --host 0.0.0.0"

help: ## This help message
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' -e 's/:.*#/: #/' | column -t -s '##'
