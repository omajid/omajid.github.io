COMMIT:=$(shell git rev-parse HEAD)
AUTHOR:="$(shell git config user.name) <$(shell git config user.email)>"

.PHONY: all
all: serve-locally

gh-pages/:
	git worktree prune
	git worktree add -B gh-pages gh-pages/ origin/gh-pages

.PHONY: serve-locally
serve-locally:
	hugo server --buildDrafts --buildFuture

.PHONY: build-and-commit-to-gh-pages-locally
build-and-commit-to-gh-pages-locally: gh-pages/
	rm -rf gh-pages/*
	hugo --destination gh-pages/
	cd gh-pages && \
	  git add --all && \
	  git commit -m "Updated content based on $(COMMIT)" --author=$(AUTHOR)

.PHONY: publish-to-github
push-to-github:
	git push --force-with-lease
	cd gh-pages && \
	  git push --force-with-lease
