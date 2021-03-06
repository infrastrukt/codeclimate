.PHONY: install uninstall image test citest bundle

PREFIX ?= /usr/local
SKIP_ENGINES ?= 0

image:
	docker build -t codeclimate/codeclimate .

test: RSPEC_ARGS ?= --tag ~slow
test: image
	docker run --rm -it \
	  --entrypoint bundle \
	  --volume /var/run/docker.sock:/var/run/docker.sock \
	  --workdir /usr/src/app \
	  codeclimate/codeclimate exec rspec $(RSPEC_ARGS)

test_all: image
	docker run --rm -it \
	  --entrypoint bundle \
	  --volume /var/run/docker.sock:/var/run/docker.sock \
	  --workdir /usr/src/app \
	  codeclimate/codeclimate exec rake spec:all spec:benchmark

citest: DOCKER_API_VERSION=$(strip $(shell docker version -f '{{ .Server.ApiVersion }}'))
citest:
	docker run \
	  --entrypoint sh \
	  --env CI \
	  --env CIRCLECI \
	  --env CIRCLE_BUILD_NUM \
	  --env CIRCLE_BRANCH \
	  --env CIRCLE_SHA1 \
	  --env CC_TEST_REPORTER_ID \
	  --env DOCKER_API_VERSION="$(DOCKER_API_VERSION)" \
	  --volume $(PWD)/.git:/usr/src/app/.git:ro \
	  --volume /var/run/docker.sock:/var/run/docker.sock \
	  --volume $(CIRCLE_TEST_REPORTS):/usr/src/app/spec/reports \
	  --workdir /usr/src/app \
	  codeclimate/codeclimate -c "bundle exec rake spec:all && ./cc-test-reporter after-build && bundle exec rake spec:benchmark"

install:
	bin/check
	docker pull codeclimate/codeclimate:latest
	@[ $(SKIP_ENGINES) -eq 1 ] || \
	  docker images | \
	  awk '/codeclimate\/codeclimate-/ { print $$1 }' | \
	  xargs -n1 docker pull 2>/dev/null || true
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	install -m 0755 codeclimate-wrapper $(DESTDIR)$(PREFIX)/bin/codeclimate

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/bin/codeclimate
	docker rmi codeclimate/codeclimate:latest

bundle:
	docker run --rm \
	  --entrypoint bundle \
	  --volume $(PWD):/usr/src/app \
	  --workdir /usr/src/app \
	  codeclimate/codeclimate $(BUNDLE_ARGS)
