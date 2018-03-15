JENKINS_CONTAINER:=jenkins/evergreen
RUBY=./tools/ruby
# This variable is used for downloading some of the "upstream" maintained
# scripts necessary for running Jenkins nicely inside of Docker
SCRIPTS_URL=https://raw.githubusercontent.com/jenkinsci/docker/master/

### Phony targets
#################
all: check container

check:
	$(MAKE) -C client $@
	$(MAKE) -C services $@
	$(MAKE) container-check

container-prereqs: build/jenkins-support build/jenkins.sh scripts/shim-startup-wrapper.sh

container-check: shunit2 ./tests/tests.sh container
	./tests/tests.sh

container: container-prereqs Dockerfile supervisord.conf fetch-versions
	docker build -t ${JENKINS_CONTAINER}:latest .

publish: container
	docker push ${JENKINS_CONTAINER}:latest

fetch-versions: essentials.yaml ./scripts/update-essentials update-center.json
	$(RUBY) ./scripts/update-essentials essentials.yaml update-center.json

clean:
	docker rmi $(shell docker images -q -f "reference=$(IMAGE_NAME)") || true
	rm -f update-center.json
	$(MAKE) -C client $@
	$(MAKE) -C services $@
#################

update-center.json:
	curl -sSL https://updates.jenkins.io/current/update-center.actual.json > update-center.json

build/jenkins.sh:
	mkdir -p build
	curl -sSL $(SCRIPTS_URL)/jenkins.sh > $@
	chmod +x $@

build/jenkins-support:
	mkdir -p build
	curl -sSL $(SCRIPTS_URL)/jenkins-support > $@
	chmod +x $@

shunit2:
	git clone https://github.com/kward/shunit2

.PHONY: all check clean container container-check container-prereqs fetch-versions
