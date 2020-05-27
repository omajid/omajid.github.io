COMMIT:=$(shell git rev-parse HEAD)
AUTHOR:="$(shell git config user.name) <$(shell git config user.email)>"

.PHONY: all
all: publish-local

public/:
	git worktree prune
	git worktree add -B master public/ origin/master

publish-local:
	hugo server -D

.PHONY: publish
publish: public/
	# FIXME abort on dirty repo
	rm -rf public/*
	hugo
	cd public && \
	  git add --all && \
	  git commit -m "Updated content based on $(COMMIT)" --author=$(AUTHOR)

.PHONY: publish-live
publish-live: publish
	cd public && \
	  git push --force-with-lease
