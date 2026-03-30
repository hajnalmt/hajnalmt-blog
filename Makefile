default: help

RUBY_IMAGE ?= ruby:2.7-bullseye
JEKYLL_SETUP = gem install bundler -v 2.3.25 && git config --global --add safe.directory /srv/jekyll && bundle _2.3.25_ install

build: ## builds a _site directory
	docker run --rm --volume="$$PWD:/srv/jekyll" --workdir="/srv/jekyll" -p 4000:4000 $(RUBY_IMAGE) bash -lc "$(JEKYLL_SETUP) && bundle _2.3.25_ exec jekyll build"

up: ## starts a live reloading container
	docker run --rm --volume="$$PWD:/srv/jekyll" --workdir="/srv/jekyll" -p 4000:4000 -p 35729:35729 $(RUBY_IMAGE) bash -lc "$(JEKYLL_SETUP) && bundle _2.3.25_ exec jekyll serve --livereload --host 0.0.0.0"

help: ## This help message
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' -e 's/:.*#/: #/' | column -t -s '##'
