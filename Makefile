SERVICE=proxy

build-prod:
	docker build ./ --tag "openslides-$(SERVICE)" --build-arg CONTEXT="prod" --target "prod"

build-dev:
	docker build ./ --tag "openslides-$(SERVICE)-dev" --build-arg CONTEXT="dev" --target "dev"

build-test:
	docker build ./ --tag "openslides-$(SERVICE)-tests" --build-arg CONTEXT="tests" --target "tests"

run-tests:
	echo "Proxy has no tests"