COMMIT:=$(shell git rev-parse HEAD)
AUTHOR:="$(shell git config user.name) <$(shell git config user.email)>"

.PHONY: all
all: serve-local

public/:
	git worktree prune
	git worktree add -B master public/ origin/master

.PHONY: serve-local
serve-local:
	hugo server --buildDrafts --buildFuture

.PHONY: publish-locally
publish-locally: public/
	# FIXME abort on dirty repo
	rm -rf public/*
	hugo
	cd public && \
	  git add --all && \
	  git commit -m "Updated content based on $(COMMIT)" --author=$(AUTHOR)

.PHONY: publish-to-github
publish-to-github:
	git push --force-with-lease
	cd public && \
	  git push --force-with-lease