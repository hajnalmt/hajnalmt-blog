default: help

build: ## builds a _site directory
	docker run -it --rm --volume="$$PWD:/srv/jekyll" -p 4000:4000 jekyll/jekyll jekyll build

up: ## starts a live reloading container
	docker run -it --rm --volume="$$PWD:/srv/jekyll" -p 4000:4000 -p 35729:35729 jekyll/jekyll jekyll serve --livereload

help: ## This help message
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' -e 's/:.*#/: #/' | column -t -s '##'
