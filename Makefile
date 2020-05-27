COMMIT:=$(shell git rev-parse HEAD)

.PHONY: all
all: publish

.PHONY: publish
publish:
	# FIXME abort on dirty repo
	test -d public
	rm -rf public/*
	hugo
	cd public && \
	 git add --all && \
	 git commit -m "Updated content based on $(COMMIT)" && \
	 git push --force-with-lease
